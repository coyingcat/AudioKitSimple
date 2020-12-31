// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import AVFoundation

/// Sequencer based on tried-and-true CoreAudio/MIDI Sequencing
open class AppleSequencer: NSObject {
    /// Music sequence
    open var sequence: MusicSequence?

    /// Pointer to Music Sequence
    open var sequencePointer: UnsafeMutablePointer<MusicSequence>?

    /// Array of AudioKit Music Tracks
    open var tracks = [MusicTrackManager]()

    /// Music Player
    var musicPlayer: MusicPlayer?

    /// Loop control
    open private(set) var loopEnabled: Bool = false

    /// Sequencer Initialization
    override public init() {
        NewMusicSequence(&sequence)
        if let existingSequence = sequence {
            sequencePointer = UnsafeMutablePointer<MusicSequence>(existingSequence)
        }
        // setup and attach to musicplayer
        NewMusicPlayer(&musicPlayer)
        if let existingMusicPlayer = musicPlayer {
            MusicPlayerSetSequence(existingMusicPlayer, sequence)
        }
    }

    deinit {
        Log("deinit:")

        if let player = musicPlayer {
            DisposeMusicPlayer(player)
        }

        if let seq = sequence {
            for track in self.tracks {
                if let intTrack = track.internalMusicTrack {
                    MusicSequenceDisposeTrack(seq, intTrack)
                }
            }

            DisposeMusicSequence(seq)
        }
    }

    /// Initialize the sequence with a MIDI file
    ///
    /// - parameter filename: Location of the MIDI File
    ///
    public convenience init(filename: String) {
        self.init()
        loadMIDIFile(filename)
    }

    /// Initialize the sequence with a MIDI file
    /// - Parameter fileURL: URL of MIDI File
    public convenience init(fromURL fileURL: URL) {
        self.init()
        loadMIDIFile(fromURL: fileURL)
    }

    /// Initialize the sequence with a MIDI file data representation
    ///
    /// - parameter fromData: Data representation of a MIDI file
    ///
    public convenience init(fromData data: Data) {
        self.init()
        loadMIDIFile(fromData: data)
    }

    /// Preroll the music player. Call this function in advance of playback to reduce the sequencers
    /// startup latency. If you call `play` without first calling this function, the sequencer will
    /// call this function before beginning playback.
    public func preroll() {
        if let existingMusicPlayer = musicPlayer {
            MusicPlayerPreroll(existingMusicPlayer)
        }
    }

    // MARK: - Looping

    /// Enable looping for all tracks - loops entire sequence
    public func enableLooping() {
        setLoopInfo(length, numberOfLoops: 0)
        loopEnabled = true
    }

    /// Enable looping for all tracks with specified length
    ///
    /// - parameter loopLength: Loop length in beats
    ///
    public func enableLooping(_ loopLength: Duration) {
        setLoopInfo(loopLength, numberOfLoops: 0)
        loopEnabled = true
    }

    /// Disable looping for all tracks
    public func disableLooping() {
        setLoopInfo(Duration(beats: 0), numberOfLoops: 0)
        loopEnabled = false
    }

    /// Set looping duration and count for all tracks
    ///
    /// - Parameters:
    ///   - duration: Duration of the loop in beats
    ///   - numberOfLoops: The number of time to repeat
    ///
    public func setLoopInfo(_ duration: Duration, numberOfLoops: Int) {
        for track in tracks {
            track.setLoopInfo(duration, numberOfLoops: numberOfLoops)
        }
        loopEnabled = true
    }

    // MARK: - Length

    /// Set length of all tracks
    ///
    /// - parameter length: Length of tracks in beats
    ///
    public func setLength(_ length: Duration) {
        for track in tracks {
            track.setLength(length)
        }
        let size: UInt32 = 0
        var len = length.musicTimeStamp
        var tempoTrack: MusicTrack?
        if let existingSequence = sequence {
            MusicSequenceGetTempoTrack(existingSequence, &tempoTrack)
        }
        if let existingTempoTrack = tempoTrack {
            MusicTrackSetProperty(existingTempoTrack, kSequenceTrackProperty_TrackLength, &len, size)
        }
    }

    /// Length of longest track in the sequence
    open var length: Duration {
        var length: MusicTimeStamp = 0
        var tmpLength: MusicTimeStamp = 0

        for track in tracks {
            tmpLength = track.length
            if tmpLength >= length { length = tmpLength }
        }

        return Duration(beats: length, tempo: tempo)
    }

    // MARK: - Tempo and Rate

    /// Set the rate of the sequencer
    ///
    /// - parameter rate: Set the rate relative to the tempo of the track
    ///
    public func setRate(_ rate: Double) {
        if let existingMusicPlayer = musicPlayer {
            MusicPlayerSetPlayRateScalar(existingMusicPlayer, MusicTimeStamp(rate))
        }
    }

    /// Rate relative to the default tempo (BPM) of the track
    open var rate: Double {
        var rate = MusicTimeStamp(1.0)
        if let existingMusicPlayer = musicPlayer {
            MusicPlayerGetPlayRateScalar(existingMusicPlayer, &rate)
        }
        return rate
    }

    /// Clears all existing tempo events and adds single tempo event at start
    /// Will also adjust the tempo immediately if sequence is playing when called
    public func setTempo(_ bpm: Double) {
        let constrainedTempo = (10 ... 280).clamp(bpm)

        var tempoTrack: MusicTrack?

        if let existingSequence = sequence {
            MusicSequenceGetTempoTrack(existingSequence, &tempoTrack)
        }
        if isPlaying {
            var currTime: MusicTimeStamp = 0
            if let existingMusicPlayer = musicPlayer {
                MusicPlayerGetTime(existingMusicPlayer, &currTime)
            }
            currTime = fmod(currTime, length.beats)
            if let existingTempoTrack = tempoTrack {
                MusicTrackNewExtendedTempoEvent(existingTempoTrack, currTime, constrainedTempo)
            }
        }
        if let existingTempoTrack = tempoTrack {
            MusicTrackClear(existingTempoTrack, 0, length.beats)
            clearTempoEvents(existingTempoTrack)
            MusicTrackNewExtendedTempoEvent(existingTempoTrack, 0, constrainedTempo)
        }
    }

    /// Add a  tempo change to the score
    ///
    /// - Parameters:
    ///   - bpm: Tempo in beats per minute
    ///   - position: Point in time in beats
    ///
    public func addTempoEventAt(tempo bpm: Double, position: Duration) {
        let constrainedTempo = (10 ... 280).clamp(bpm)

        var tempoTrack: MusicTrack?

        if let existingSequence = sequence {
            MusicSequenceGetTempoTrack(existingSequence, &tempoTrack)
        }
        if let existingTempoTrack = tempoTrack {
            MusicTrackNewExtendedTempoEvent(existingTempoTrack, position.beats, constrainedTempo)
        }
    }

    /// Tempo retrieved from the sequencer. Defaults to 120
    /// NB: It looks at the currentPosition back in time for the last tempo event.
    /// If the sequence is not started, it returns default 120
    /// A sequence may contain several tempo events.
    open var tempo: Double {
        var tempoOut: Double = 120.0

        var tempoTrack: MusicTrack?
        if let existingSequence = sequence {
            MusicSequenceGetTempoTrack(existingSequence, &tempoTrack)
        }

        var tempIterator: MusicEventIterator?
        if let existingTempoTrack = tempoTrack {
            NewMusicEventIterator(existingTempoTrack, &tempIterator)
        }
        guard let iterator = tempIterator else {
            return 0.0
        }

        var eventTime: MusicTimeStamp = 0
        var eventType: MusicEventType = kMusicEventType_ExtendedTempo
        var eventData: UnsafeRawPointer?
        var eventDataSize: UInt32 = 0

        var hasPreviousEvent: DarwinBoolean = false
        MusicEventIteratorSeek(iterator, currentPosition.beats)
        MusicEventIteratorHasPreviousEvent(iterator, &hasPreviousEvent)
        if hasPreviousEvent.boolValue {
            MusicEventIteratorPreviousEvent(iterator)
            MusicEventIteratorGetEventInfo(iterator, &eventTime, &eventType, &eventData, &eventDataSize)
            if eventType == kMusicEventType_ExtendedTempo {
                if let data = eventData?.assumingMemoryBound(to: ExtendedTempoEvent.self) {
                    let tempoEventPointer: UnsafePointer<ExtendedTempoEvent> = UnsafePointer(data)
                    tempoOut = tempoEventPointer.pointee.bpm
                }
            }
        }
        DisposeMusicEventIterator(iterator)
        return tempoOut
    }

    /// returns an array of (MusicTimeStamp, bpm) tuples
    /// for all tempo events on the tempo track
    open var allTempoEvents: [(MusicTimeStamp, Double)] {
        var tempoTrack: MusicTrack?
        guard let existingSequence = sequence else { return [] }
        MusicSequenceGetTempoTrack(existingSequence, &tempoTrack)

        var tempos = [(MusicTimeStamp, Double)]()

        if let tempoTrack = tempoTrack {
            MusicTrackManager.iterateMusicTrack(tempoTrack) { _, eventTime, eventType, eventData, _, _ in
                if eventType == kMusicEventType_ExtendedTempo {
                    if let data = eventData?.assumingMemoryBound(to: ExtendedTempoEvent.self) {
                        let tempoEventPointer: UnsafePointer<ExtendedTempoEvent> = UnsafePointer(data)
                        tempos.append((eventTime, tempoEventPointer.pointee.bpm))
                    }
                }
            }
        }
        return tempos
    }

    /// returns the tempo at a given position in beats
    /// - parameter at: Position at which the tempo is desired
    ///
    /// if there is more than one event precisely at the requested position
    /// it will return the most recently added
    /// Will return default 120 if there is no tempo event at or before position
    public func getTempo(at position: MusicTimeStamp) -> Double {
        // MIDI file with no tempo events defaults to 120 bpm
        var tempoAtPosition: Double = 120.0
        for event in allTempoEvents {
            if event.0 <= position {
                tempoAtPosition = event.1
            } else {
                break
            }
        }

        return tempoAtPosition
    }

    // Remove existing tempo events
    func clearTempoEvents(_ track: MusicTrack) {
        MusicTrackManager.iterateMusicTrack(track) { iterator, _, eventType, _, _, isReadyForNextEvent in
            isReadyForNextEvent = true
            if eventType == kMusicEventType_ExtendedTempo {
                MusicEventIteratorDeleteEvent(iterator)
                isReadyForNextEvent = false
            }
        }
    }

    // MARK: - Time Signature

    /// Return and array of (MusicTimeStamp, TimeSignature) tuples
    open var allTimeSignatureEvents: [(MusicTimeStamp, TimeSignature)] {
        struct TimeSignatureEvent {
            var metaEventType: MIDIByte = 0
            var unused1: MIDIByte = 0
            var unused2: MIDIByte = 0
            var unused3: MIDIByte = 0
            var dataLength: UInt32 = 0
            var data: (MIDIByte, MIDIByte, MIDIByte, MIDIByte) = (0, 0, 0, 0)
        }

        var tempoTrack: MusicTrack?
        var result = [(MusicTimeStamp, TimeSignature)]()

        if let existingSequence = sequence {
            MusicSequenceGetTempoTrack(existingSequence, &tempoTrack)
        }

        guard let unwrappedTempoTrack = tempoTrack else {
            Log("Couldn't get tempo track")
            return result
        }

        let timeSignatureMetaEventByte: MIDIByte = 0x58
        MusicTrackManager.iterateMusicTrack(unwrappedTempoTrack) { _, eventTime, eventType, eventData, dataSize, _ in
            guard let eventData = eventData else { return }
            guard eventType == kMusicEventType_Meta else { return }

            let metaEventPointer = eventData.bindMemory(to: MIDIMetaEvent.self, capacity: Int(dataSize))
            let metaEvent = metaEventPointer.pointee
            if metaEvent.metaEventType == timeSignatureMetaEventByte {
                let timeSigPointer = eventData.bindMemory(to: TimeSignatureEvent.self, capacity: Int(dataSize))
                let rawTimeSig = timeSigPointer.pointee
                guard let bottomValue = TimeSignature.TimeSignatureBottomValue(rawValue: rawTimeSig.data.1) else {
                    Log("Inavlid time signature bottom value")
                    return
                }
                let timeSigEvent = TimeSignature(topValue: rawTimeSig.data.0,
                                                   bottomValue: bottomValue)
                result.append((eventTime, timeSigEvent))
            }
        }

        return result
    }

    /// returns the time signature at a given position in beats
    /// - parameter at: Position at which the time signature is desired
    ///
    /// If there is more than one event precisely at the requested position
    /// it will return the most recently added.
    /// Will return 4/4 if there is no Time Signature event at or before position
    public func getTimeSignature(at position: MusicTimeStamp) -> TimeSignature {
        var outTimeSignature = TimeSignature() // 4/4, by default
        for event in allTimeSignatureEvents {
            if event.0 <= position {
                outTimeSignature = event.1
            } else {
                break
            }
        }

        return outTimeSignature
    }

    /// Add a time signature event to start of tempo track
    /// NB: will affect MIDI file layout but NOT sequencer playback
    ///
    /// - Parameters:
    ///   - at: MusicTimeStamp where time signature event will be placed
    ///   - timeSignature: Time signature for added event
    ///   - ticksPerMetronomeClick: MIDI clocks between metronome clicks (not PPQN), typically 24
    ///   - thirtySecondNotesPerQuarter: Number of 32nd notes making a quarter, typically 8
    ///   - clearExistingEvents: Flag that will clear other Time Signature Events from tempo track
    ///
    public func addTimeSignatureEvent(at timeStamp: MusicTimeStamp = 0.0,
                                      timeSignature: TimeSignature,
                                      ticksPerMetronomeClick: MIDIByte = 24,
                                      thirtySecondNotesPerQuarter: MIDIByte = 8,
                                      clearExistingEvents: Bool = true) {
        var tempoTrack: MusicTrack?
        if let existingSequence = sequence {
            MusicSequenceGetTempoTrack(existingSequence, &tempoTrack)
        }

        guard let unwrappedTempoTrack = tempoTrack else {
            Log("Couldn't get tempo track")
            return
        }

        if clearExistingEvents {
            clearTimeSignatureEvents(unwrappedTempoTrack)
        }

        let data: [MIDIByte] = [timeSignature.topValue,
                                timeSignature.bottomValue.rawValue,
                                ticksPerMetronomeClick,
                                thirtySecondNotesPerQuarter]

        let metaEventPtr = MIDIMetaEvent.allocate(metaEventType: 0x58, // i.e, set time signature
                                                  data: data)

        defer { metaEventPtr.deallocate() }

        let result = MusicTrackNewMetaEvent(unwrappedTempoTrack, timeStamp, metaEventPtr)
        if result != 0 {
            Log("Unable to set time signature")
        }
    }

    /// Remove existing time signature events from tempo track
    func clearTimeSignatureEvents(_ track: MusicTrack) {
        let timeSignatureMetaEventByte: MIDIByte = 0x58
        let metaEventType = kMusicEventType_Meta

        MusicTrackManager.iterateMusicTrack(track) { iterator, _, eventType, eventData, _, isReadyForNextEvent in
            isReadyForNextEvent = true
            guard eventType == metaEventType else { return }

            let data = UnsafePointer<MIDIMetaEvent>(eventData?.assumingMemoryBound(to: MIDIMetaEvent.self))
            guard let dataMetaEventType = data?.pointee.metaEventType else { return }

            if dataMetaEventType == timeSignatureMetaEventByte {
                MusicEventIteratorDeleteEvent(iterator)
                isReadyForNextEvent = false
            }
        }
    }

    // MARK: - Duration

    /// Convert seconds into Duration
    ///
    /// - parameter seconds: time in seconds
    ///
    public func duration(seconds: Double) -> Duration {
        let sign = seconds > 0 ? 1.0 : -1.0
        let absoluteValueSeconds = fabs(seconds)
        var outBeats = Duration(beats: MusicTimeStamp())
        if let existingSequence = sequence {
            MusicSequenceGetBeatsForSeconds(existingSequence, Float64(absoluteValueSeconds), &outBeats.beats)
        }
        outBeats.beats *= sign
        return outBeats
    }

    /// Convert beats into seconds
    ///
    /// - parameter duration: Duration
    ///
    public func seconds(duration: Duration) -> Double {
        let sign = duration.beats > 0 ? 1.0 : -1.0
        let absoluteValueBeats = fabs(duration.beats)
        var outSecs: Double = MusicTimeStamp()
        if let existingSequence = sequence {
            MusicSequenceGetSecondsForBeats(existingSequence, absoluteValueBeats, &outSecs)
        }
        outSecs *= sign
        return outSecs
    }

    // MARK: - Transport Control

    /// Play the sequence
    public func play() {
        if let existingMusicPlayer = musicPlayer {
            MusicPlayerStart(existingMusicPlayer)
        }
    }

    /// Stop the sequence
    public func stop() {
        if let existingMusicPlayer = musicPlayer {
            MusicPlayerStop(existingMusicPlayer)
        }
    }

    /// Rewind the sequence
    public func rewind() {
        if let existingMusicPlayer = musicPlayer {
            MusicPlayerSetTime(existingMusicPlayer, 0)
        }
    }

    /// Wheter or not the sequencer is currently playing
    open var isPlaying: Bool {
        var isPlayingBool: DarwinBoolean = false
        if let existingMusicPlayer = musicPlayer {
            MusicPlayerIsPlaying(existingMusicPlayer, &isPlayingBool)
        }
        return isPlayingBool.boolValue
    }

    /// Current Time
    open var currentPosition: Duration {
        var currentTime = MusicTimeStamp()
        if let existingMusicPlayer = musicPlayer {
            MusicPlayerGetTime(existingMusicPlayer, &currentTime)
        }
        let duration = Duration(beats: currentTime)
        return duration
    }

    /// Current Time relative to sequencer length
    open var currentRelativePosition: Duration {
        return currentPosition % length // can switch to modTime func when/if % is removed
    }

    // MARK: - Loading MIDI files

    /// Load a MIDI file from the bundle (removes old tracks, if present)
    public func loadMIDIFile(_ filename: String) {
        let bundle = Bundle.main
        guard let file = bundle.path(forResource: filename, ofType: "mid") else {
            Log("No midi file found")
            return
        }
        let fileURL = URL(fileURLWithPath: file)
        loadMIDIFile(fromURL: fileURL)
    }

    /// Load a MIDI file given a URL (removes old tracks, if present)
    public func loadMIDIFile(fromURL fileURL: URL) {
        removeTracks()
        if let existingSequence = sequence {
            let status: OSStatus = MusicSequenceFileLoad(existingSequence,
                                                         fileURL as CFURL,
                                                         .midiType,
                                                         MusicSequenceLoadFlags())
            if status != OSStatus(noErr) {
                Log("error reading midi file url: \(fileURL), read status: \(status)")
            }
        }
        initTracks()
    }

    /// Load a MIDI file given its data representation (removes old tracks, if present)
    public func loadMIDIFile(fromData data: Data) {
        removeTracks()
        if let existingSequence = sequence {
            let status: OSStatus = MusicSequenceFileLoadData(existingSequence,
                                                             data as CFData,
                                                             .midiType,
                                                             MusicSequenceLoadFlags())
            if status != OSStatus(noErr) {
                Log("error reading midi data, read status: \(status)")
            }
        }
        initTracks()
    }

    /// Initialize all tracks
    ///
    /// Rebuilds tracks based on actual contents of music sequence
    ///
    func initTracks() {
        var count: UInt32 = 0
        if let existingSequence = sequence {
            MusicSequenceGetTrackCount(existingSequence, &count)
        }

        for i in 0 ..< count {
            var musicTrack: MusicTrack?
            if let existingSequence = sequence {
                MusicSequenceGetIndTrack(existingSequence, UInt32(i), &musicTrack)
            }
            if let existingMusicTrack = musicTrack {
                tracks.append(MusicTrackManager(musicTrack: existingMusicTrack, name: "InitializedTrack"))
            }
        }

        if loopEnabled {
            enableLooping()
        }
    }

    ///  Dispose of tracks associated with sequence
    func removeTracks() {
        if let existingSequence = sequence {
            var tempoTrack: MusicTrack?
            MusicSequenceGetTempoTrack(existingSequence, &tempoTrack)
            if let track = tempoTrack {
                MusicTrackClear(track, 0, length.musicTimeStamp)
                clearTimeSignatureEvents(track)
                clearTempoEvents(track)
            }

            for track in tracks {
                if let internalTrack = track.internalMusicTrack {
                    MusicSequenceDisposeTrack(existingSequence, internalTrack)
                }
            }
        }
        tracks.removeAll()
    }

    // MARK: - Delete Tracks


    /// Clear all non-tempo events from all tracks within the specified range
    //
    /// - Parameters:
    ///   - start: Start of the range to clear, in beats (inclusive)
    ///   - duration: Length of time after the start position to clear, in beats (exclusive)
    ///
    public func clearRange(start: Duration, duration: Duration) {
        for track in tracks {
            track.clearRange(start: start, duration: duration)
        }
    }

    /// Set the music player time directly
    ///
    /// - parameter time: Music time stamp to set
    ///
    public func setTime(_ time: MusicTimeStamp) {
        if let existingMusicPlayer = musicPlayer {
            MusicPlayerSetTime(existingMusicPlayer, time)
        }
    }


    /// Print sequence to console
    public func debug() {
        if let existingPointer = sequencePointer {
            CAShow(existingPointer)
        }
    }

    /// Set the midi output for all tracks

    public func setGlobalMIDIOutput(_ midiEndpoint: MIDIEndpointRef) {
        for track in tracks {
            track.setMIDIOutput(midiEndpoint)
        }
    }

    /// Time modulus
    func modTime(_ time: Double) -> Double {
        return time.truncatingRemainder(dividingBy: length.beats)
    }
}
