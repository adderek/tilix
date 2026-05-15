/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
module gx.tilix.terminal.bellplayer;

import std.experimental.logger;
import std.format;

import glib.URI;
import glib.c.functions : g_timeout_add, g_source_remove;
import glib.c.types : GSourceFunc;

import gobject.ObjectG;
import gstreamer.Bin;
import gstreamer.Element;
import gstreamer.GStreamer;
import gstreamer.Parse;
import gstreamer.c.types : GstState;

/**
 * Plays BEL sounds via GStreamer with optional volume fade-out.
 */
class BellPlayer {
private:
    Element _pipeline;
    Element _volumeEl;
    uint _fadeId = 0;
    double _currentVolume = 1.0;
    double _fadeStep = 0.0;

    static bool _gstInitialized = false;

    static void ensureGstInit() {
        if (!_gstInitialized) {
            string[] empty;
            GStreamer.init(empty);
            _gstInitialized = true;
        }
    }

    void stopInternal() {
        if (_fadeId > 0) {
            g_source_remove(_fadeId);
            _fadeId = 0;
        }
        if (_pipeline !is null) {
            _pipeline.setState(GstState.NULL);
            _pipeline = null;
            _volumeEl = null;
        }
        _currentVolume = 1.0;
    }

    extern(C) static bool onFadeTick(BellPlayer self) {
        self._currentVolume -= self._fadeStep;
        if (self._currentVolume <= 0.0) {
            if (self._volumeEl !is null) self._volumeEl.setProperty("volume", 0.0);
            self.stopInternal();
            return false;
        }
        if (self._volumeEl !is null) {
            self._volumeEl.setProperty("volume", self._currentVolume);
        }
        return true;
    }

public:
    ~this() { stopInternal(); }

    bool isPlaying() { return _pipeline !is null; }

    void play(string file) {
        stopInternal();
        ensureGstInit();
        try {
            string uri = URI.filenameToUri(file, null);
            string desc = format(`uridecodebin uri="%s" ! audioconvert ! audioresample ! volume name=vol ! autoaudiosink`, uri);
            _pipeline = Parse.launch(desc);
            if (_pipeline is null) return;
            if (auto bin = cast(Bin) _pipeline) {
                _volumeEl = bin.getByName("vol");
            }
            _currentVolume = 1.0;
            if (_volumeEl !is null) _volumeEl.setProperty("volume", _currentVolume);
            _pipeline.setState(GstState.PLAYING);
        } catch (Exception e) {
            errorf("BellPlayer: failed to play '%s': %s", file, e.msg);
            _pipeline = null;
            _volumeEl = null;
        }
    }

    /**
     * Gradually reduce volume to zero over durationMs milliseconds, then stop.
     * No-op if not currently playing.
     */
    void fadeOut(int durationMs) {
        if (_pipeline is null) return;
        if (_fadeId > 0) {
            g_source_remove(_fadeId);
            _fadeId = 0;
        }
        int ticks = durationMs / 50;
        if (ticks < 1) ticks = 1;
        _fadeStep = _currentVolume / ticks;
        _fadeId = g_timeout_add(50, cast(GSourceFunc) &onFadeTick, cast(void*) this);
    }

    void stop() { stopInternal(); }
}
