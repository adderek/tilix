/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
module gx.tilix.terminal.exvte;

import core.sys.posix.unistd;

import std.algorithm;
import std.experimental.logger;

import gdk.Event;
import gdk.RGBA;

import gobject.Signals;

import glib.Str;

import vte.Terminal;
import vtec.vtetypes;

import gx.tilix.constants;
import gx.tilix.terminal.util;

enum TerminalScreen {
    NORMAL = 0,
    ALTERNATE = 1
};

/**
 * Extends default GtKD VTE widget to support various patches
 * which provide additional features when available.
 */
class ExtendedVTE : Terminal {

private:
    bool ignoreFirstNotification = true;

public:

    /**
	 * Sets our main struct and passes it to the parent class.
	 */
    this(VteTerminal* vteTerminal, bool ownedRef = false) {
        super(vteTerminal, ownedRef);
    }

    /**
	 * Creates a new terminal widget.
	 *
	 * Return: a new #VteTerminal object
	 *
	 * Throws: ConstructionException GTK+ fails to create the object.
	 */
    this() {
        super();
    }

    debug(Destructors) {
        ~this() {
            import std.stdio: writeln;
            writeln("******** VTE Destructor");
        }
    }

	protected class OnTilixBellDelegateWrapper
	{
		void delegate(string, Terminal) dlg;
		gulong handlerId;
		ConnectFlags flags;
		this(void delegate(string, Terminal) dlg, gulong handlerId, ConnectFlags flags)
		{
			this.dlg = dlg;
			this.handlerId = handlerId;
			this.flags = flags;
		}
	}
	protected OnTilixBellDelegateWrapper[] onTilixBellListeners;

	/**
	 * Emitted when OSC 777 ; tilix-bell ; params BEL is received.
	 * params format: "level[;fade=ms][;msg=text]"
	 * level: info | warning | error | success
	 */
	gulong addOnTilixBell(void delegate(string, Terminal) dlg, ConnectFlags connectFlags=cast(ConnectFlags)0)
	{
		onTilixBellListeners ~= new OnTilixBellDelegateWrapper(dlg, 0, connectFlags);
		onTilixBellListeners[onTilixBellListeners.length - 1].handlerId = Signals.connectData(
			this,
			"tilix-bell",
			cast(GCallback)&callBackTilixBell,
			cast(void*)onTilixBellListeners[onTilixBellListeners.length - 1],
			cast(GClosureNotify)&callBackTilixBellDestroy,
			connectFlags);
		return onTilixBellListeners[onTilixBellListeners.length - 1].handlerId;
	}

	extern(C) static void callBackTilixBell(VteTerminal* terminalStruct, char* params, OnTilixBellDelegateWrapper wrapper)
	{
		wrapper.dlg(Str.toString(params), wrapper.outer);
	}

	extern(C) static void callBackTilixBellDestroy(OnTilixBellDelegateWrapper wrapper, GClosure* closure)
	{
		wrapper.outer.internalRemoveOnTilixBell(wrapper);
	}

	protected void internalRemoveOnTilixBell(OnTilixBellDelegateWrapper source)
	{
		foreach(index, wrapper; onTilixBellListeners)
		{
			if (wrapper.dlg == source.dlg && wrapper.flags == source.flags && wrapper.handlerId == source.handlerId)
			{
				onTilixBellListeners[index] = null;
				onTilixBellListeners = std.algorithm.remove(onTilixBellListeners, index);
				break;
			}
		}
	}

	protected class OnTilixFoldStartDelegateWrapper
	{
		void delegate(string, Terminal) dlg;
		gulong handlerId;
		ConnectFlags flags;
		this(void delegate(string, Terminal) dlg, gulong handlerId, ConnectFlags flags)
		{
			this.dlg = dlg;
			this.handlerId = handlerId;
			this.flags = flags;
		}
	}
	protected OnTilixFoldStartDelegateWrapper[] onTilixFoldStartListeners;

	/**
	 * Emitted when OSC 777 ; tilix-fold-start ; params BEL is received.
	 * params format: "id=X;title=Y;state=Z;row=N"
	 */
	gulong addOnTilixFoldStart(void delegate(string, Terminal) dlg, ConnectFlags connectFlags=cast(ConnectFlags)0)
	{
		onTilixFoldStartListeners ~= new OnTilixFoldStartDelegateWrapper(dlg, 0, connectFlags);
		onTilixFoldStartListeners[onTilixFoldStartListeners.length - 1].handlerId = Signals.connectData(
			this,
			"tilix-fold-start",
			cast(GCallback)&callBackTilixFoldStart,
			cast(void*)onTilixFoldStartListeners[onTilixFoldStartListeners.length - 1],
			cast(GClosureNotify)&callBackTilixFoldStartDestroy,
			connectFlags);
		return onTilixFoldStartListeners[onTilixFoldStartListeners.length - 1].handlerId;
	}

	extern(C) static void callBackTilixFoldStart(VteTerminal* terminalStruct, char* params, OnTilixFoldStartDelegateWrapper wrapper)
	{
		wrapper.dlg(Str.toString(params), wrapper.outer);
	}

	extern(C) static void callBackTilixFoldStartDestroy(OnTilixFoldStartDelegateWrapper wrapper, GClosure* closure)
	{
		wrapper.outer.internalRemoveOnTilixFoldStart(wrapper);
	}

	protected void internalRemoveOnTilixFoldStart(OnTilixFoldStartDelegateWrapper source)
	{
		foreach(index, wrapper; onTilixFoldStartListeners)
		{
			if (wrapper.dlg == source.dlg && wrapper.flags == source.flags && wrapper.handlerId == source.handlerId)
			{
				onTilixFoldStartListeners[index] = null;
				onTilixFoldStartListeners = std.algorithm.remove(onTilixFoldStartListeners, index);
				break;
			}
		}
	}

	protected class OnTilixFoldEndDelegateWrapper
	{
		void delegate(string, Terminal) dlg;
		gulong handlerId;
		ConnectFlags flags;
		this(void delegate(string, Terminal) dlg, gulong handlerId, ConnectFlags flags)
		{
			this.dlg = dlg;
			this.handlerId = handlerId;
			this.flags = flags;
		}
	}
	protected OnTilixFoldEndDelegateWrapper[] onTilixFoldEndListeners;

	/**
	 * Emitted when OSC 777 ; tilix-fold-end ; params BEL is received.
	 * params format: "id=X;summary=Y;row=N"
	 */
	gulong addOnTilixFoldEnd(void delegate(string, Terminal) dlg, ConnectFlags connectFlags=cast(ConnectFlags)0)
	{
		onTilixFoldEndListeners ~= new OnTilixFoldEndDelegateWrapper(dlg, 0, connectFlags);
		onTilixFoldEndListeners[onTilixFoldEndListeners.length - 1].handlerId = Signals.connectData(
			this,
			"tilix-fold-end",
			cast(GCallback)&callBackTilixFoldEnd,
			cast(void*)onTilixFoldEndListeners[onTilixFoldEndListeners.length - 1],
			cast(GClosureNotify)&callBackTilixFoldEndDestroy,
			connectFlags);
		return onTilixFoldEndListeners[onTilixFoldEndListeners.length - 1].handlerId;
	}

	extern(C) static void callBackTilixFoldEnd(VteTerminal* terminalStruct, char* params, OnTilixFoldEndDelegateWrapper wrapper)
	{
		wrapper.dlg(Str.toString(params), wrapper.outer);
	}

	extern(C) static void callBackTilixFoldEndDestroy(OnTilixFoldEndDelegateWrapper wrapper, GClosure* closure)
	{
		wrapper.outer.internalRemoveOnTilixFoldEnd(wrapper);
	}

	protected void internalRemoveOnTilixFoldEnd(OnTilixFoldEndDelegateWrapper source)
	{
		foreach(index, wrapper; onTilixFoldEndListeners)
		{
			if (wrapper.dlg == source.dlg && wrapper.flags == source.flags && wrapper.handlerId == source.handlerId)
			{
				onTilixFoldEndListeners[index] = null;
				onTilixFoldEndListeners = std.algorithm.remove(onTilixFoldEndListeners, index);
				break;
			}
		}
	}

	protected class OnTilixFoldsClearedDelegateWrapper
	{
		void delegate(Terminal) dlg;
		gulong handlerId;
		ConnectFlags flags;
		this(void delegate(Terminal) dlg, gulong handlerId, ConnectFlags flags)
		{
			this.dlg = dlg;
			this.handlerId = handlerId;
			this.flags = flags;
		}
	}
	protected OnTilixFoldsClearedDelegateWrapper[] onTilixFoldsClearedListeners;

	/**
	 * Emitted when VTE drops all fold records (rewrap resize, hard reset).
	 */
	gulong addOnTilixFoldsCleared(void delegate(Terminal) dlg, ConnectFlags connectFlags=cast(ConnectFlags)0)
	{
		onTilixFoldsClearedListeners ~= new OnTilixFoldsClearedDelegateWrapper(dlg, 0, connectFlags);
		onTilixFoldsClearedListeners[onTilixFoldsClearedListeners.length - 1].handlerId = Signals.connectData(
			this,
			"tilix-folds-cleared",
			cast(GCallback)&callBackTilixFoldsCleared,
			cast(void*)onTilixFoldsClearedListeners[onTilixFoldsClearedListeners.length - 1],
			cast(GClosureNotify)&callBackTilixFoldsClearedDestroy,
			connectFlags);
		return onTilixFoldsClearedListeners[onTilixFoldsClearedListeners.length - 1].handlerId;
	}

	extern(C) static void callBackTilixFoldsCleared(VteTerminal* terminalStruct, OnTilixFoldsClearedDelegateWrapper wrapper)
	{
		wrapper.dlg(wrapper.outer);
	}

	extern(C) static void callBackTilixFoldsClearedDestroy(OnTilixFoldsClearedDelegateWrapper wrapper, GClosure* closure)
	{
		wrapper.outer.internalRemoveOnTilixFoldsCleared(wrapper);
	}

	protected void internalRemoveOnTilixFoldsCleared(OnTilixFoldsClearedDelegateWrapper source)
	{
		foreach(index, wrapper; onTilixFoldsClearedListeners)
		{
			if (wrapper.dlg == source.dlg && wrapper.flags == source.flags && wrapper.handlerId == source.handlerId)
			{
				onTilixFoldsClearedListeners[index] = null;
				onTilixFoldsClearedListeners = std.algorithm.remove(onTilixFoldsClearedListeners, index);
				break;
			}
		}
	}

	/** Toggle a fold section collapsed/expanded via the C API. */
	void tilixSetFoldState(string foldId, long headerRow, bool collapsed) {
		import std.string : toStringz;
		vte_terminal_tilix_set_fold_state(vteTerminal, foldId.toStringz, headerRow, collapsed ? 1 : 0);
	}

	protected class OnNotificationReceivedDelegateWrapper
	{
		void delegate(string, string, Terminal) dlg;
		gulong handlerId;
		ConnectFlags flags;
		this(void delegate(string, string, Terminal) dlg, gulong handlerId, ConnectFlags flags)
		{
			this.dlg = dlg;
			this.handlerId = handlerId;
			this.flags = flags;
		}
	}
	protected OnNotificationReceivedDelegateWrapper[] onNotificationReceivedListeners;

	/**
	 * Emitted when a process running in the terminal wants to
	 * send a notification to the desktop environment.
	 *
	 * Params:
	 *     summary = The summary
	 *     bod = Extra optional text
	 */
	gulong addOnNotificationReceived(void delegate(string, string, Terminal) dlg, ConnectFlags connectFlags=cast(ConnectFlags)0)
	{
		if (Signals.lookup("notification-received", getType()) != 0) {
			onNotificationReceivedListeners ~= new OnNotificationReceivedDelegateWrapper(dlg, 0, connectFlags);
			onNotificationReceivedListeners[onNotificationReceivedListeners.length - 1].handlerId = Signals.connectData(
				this,
				"notification-received",
				cast(GCallback)&callBackNotificationReceived,
				cast(void*)onNotificationReceivedListeners[onNotificationReceivedListeners.length - 1],
				cast(GClosureNotify)&callBackNotificationReceivedDestroy,
				connectFlags);
			return onNotificationReceivedListeners[onNotificationReceivedListeners.length - 1].handlerId;
		} else {
			return 0;
		}
	}

	extern(C) static void callBackNotificationReceived(VteTerminal* terminalStruct, char* summary, char* bod,OnNotificationReceivedDelegateWrapper wrapper)
	{
		wrapper.dlg(Str.toString(summary), Str.toString(bod), wrapper.outer);
	}

	extern(C) static void callBackNotificationReceivedDestroy(OnNotificationReceivedDelegateWrapper wrapper, GClosure* closure)
	{
		wrapper.outer.internalRemoveOnNotificationReceived(wrapper);
	}

	protected void internalRemoveOnNotificationReceived(OnNotificationReceivedDelegateWrapper source)
	{
		foreach(index, wrapper; onNotificationReceivedListeners)
		{
			if (wrapper.dlg == source.dlg && wrapper.flags == source.flags && wrapper.handlerId == source.handlerId)
			{
				onNotificationReceivedListeners[index] = null;
				onNotificationReceivedListeners = std.algorithm.remove(onNotificationReceivedListeners, index);
				break;
			}
		}
	}

	protected class OnTerminalScreenChangedDelegateWrapper
	{
		void delegate(int, Terminal) dlg;
		gulong handlerId;
		ConnectFlags flags;
		this(void delegate(int, Terminal) dlg, gulong handlerId, ConnectFlags flags)
		{
			this.dlg = dlg;
			this.handlerId = handlerId;
			this.flags = flags;
		}
	}
	protected OnTerminalScreenChangedDelegateWrapper[] onTerminalScreenChangedListeners;

	/** */
	gulong addOnTerminalScreenChanged(void delegate(int, Terminal) dlg, ConnectFlags connectFlags=cast(ConnectFlags)0)
	{
		if (Signals.lookup("terminal-screen-changed", getType()) != 0) {
			onTerminalScreenChangedListeners ~= new OnTerminalScreenChangedDelegateWrapper(dlg, 0, connectFlags);
			onTerminalScreenChangedListeners[onTerminalScreenChangedListeners.length - 1].handlerId = Signals.connectData(
				this,
				"terminal-screen-changed",
				cast(GCallback)&callBackTerminalScreenChanged,
				cast(void*)onTerminalScreenChangedListeners[onTerminalScreenChangedListeners.length - 1],
				cast(GClosureNotify)&callBackTerminalScreenChangedDestroy,
				connectFlags);
			return onTerminalScreenChangedListeners[onTerminalScreenChangedListeners.length - 1].handlerId;
		} else {
			return 0;
		}
	}

	extern(C) static void callBackTerminalScreenChanged(VteTerminal* terminalStruct, int object,OnTerminalScreenChangedDelegateWrapper wrapper)
	{
		wrapper.dlg(object, wrapper.outer);
	}

	extern(C) static void callBackTerminalScreenChangedDestroy(OnTerminalScreenChangedDelegateWrapper wrapper, GClosure* closure)
	{
		wrapper.outer.internalRemoveOnTerminalScreenChanged(wrapper);
	}

	protected void internalRemoveOnTerminalScreenChanged(OnTerminalScreenChangedDelegateWrapper source)
	{
		foreach(index, wrapper; onTerminalScreenChangedListeners)
		{
			if (wrapper.dlg == source.dlg && wrapper.flags == source.flags && wrapper.handlerId == source.handlerId)
			{
				onTerminalScreenChangedListeners[index] = null;
				onTerminalScreenChangedListeners = std.algorithm.remove(onTerminalScreenChangedListeners, index);
				break;
			}
		}
	}

    public bool getDisableBGDraw() {
		return vte_terminal_get_disable_bg_draw(vteTerminal) != 0;
    }

    public void setDisableBGDraw(bool isDisabled) {
		vte_terminal_set_disable_bg_draw(vteTerminal, isDisabled);
    }

static if (COMPILE_VTE_BACKGROUND_COLOR) {
    public void getColorBackgroundForDraw(RGBA background) {
		vte_terminal_get_color_background_for_draw(vteTerminal, background is null? null: background.getRGBAStruct());
    }
}

    /**
     * Returns the child pid running in the terminal or -1
     * if no child pid is running. May also return the VTE gpid
     * as well which also indicates no child process.
     */
    pid_t getChildPid() {
		if (isFlatpak()) {
            warning("getChildPid should not be called from a Flatpak environment.");
			return -1;
		} else {
			if (getPty() is null)
            	return false;
        	return tcgetpgrp(getPty().getFd());
		}
    }

    /**
     * Returns the absolute terminal row at the given pixel Y coordinate,
     * accounting for folded (hidden) rows.
     * Returns -1 on error.
     */
    long tilixRowAtY(int y) {
        return c_vte_terminal_tilix_row_at_y(vteTerminal, y);
    }

    /**
     * Hit-tests the fold toggle area (first 3 columns of a fold header row)
     * at widget-relative pixel coordinates; padding is handled by VTE.
     * Returns the absolute header row of a toggleable fold, or -1.
     */
    long tilixFoldHeaderAt(double x, double y) {
        return c_vte_terminal_tilix_fold_header_at(vteTerminal, x, y);
    }

    /**
     * Hit-tests like tilixFoldHeaderAt and toggles the fold on a hit.
     * VTE records are the source of truth (they survive rewrap resizes).
     * Returns the toggled fold's absolute header row, or -1.
     */
    long tilixToggleFoldAt(double x, double y) {
        return c_vte_terminal_tilix_toggle_fold_at(vteTerminal, x, y);
    }

    string tilixGetFoldDebugInfo() {
        import glib.c.functions : g_free;
        char* raw = c_vte_terminal_tilix_get_fold_debug_info(vteTerminal);
        if (raw is null) return "";
        scope(exit) g_free(raw);
        import std.string : fromStringz;
        return fromStringz(raw).idup;
    }
}

private:

import gtkc.Loader;
import vte.c.functions;

__gshared extern(C) {
	int function(VteTerminal* terminal) c_vte_terminal_get_disable_bg_draw;
	void function(VteTerminal* terminal, int isAudible) c_vte_terminal_set_disable_bg_draw;
	void function(VteTerminal* terminal, const(char)* fold_id, long header_row, int collapsed) c_vte_terminal_tilix_set_fold_state;
	long function(VteTerminal* terminal, int y) c_vte_terminal_tilix_row_at_y;
	long function(VteTerminal* terminal, double x, double y) c_vte_terminal_tilix_fold_header_at;
	long function(VteTerminal* terminal, double x, double y) c_vte_terminal_tilix_toggle_fold_at;
	char* function(VteTerminal* terminal) c_vte_terminal_tilix_get_fold_debug_info;

	static if (COMPILE_VTE_BACKGROUND_COLOR) {
		void function(VteTerminal* terminal, GdkRGBA* color) c_vte_terminal_get_color_background_for_draw;
	}
}

alias vte_terminal_get_disable_bg_draw = c_vte_terminal_get_disable_bg_draw;
alias vte_terminal_set_disable_bg_draw = c_vte_terminal_set_disable_bg_draw;
alias vte_terminal_tilix_set_fold_state = c_vte_terminal_tilix_set_fold_state;
alias vte_terminal_tilix_row_at_y = c_vte_terminal_tilix_row_at_y;
alias vte_terminal_tilix_fold_header_at = c_vte_terminal_tilix_fold_header_at;
alias vte_terminal_tilix_toggle_fold_at = c_vte_terminal_tilix_toggle_fold_at;
alias vte_terminal_tilix_get_fold_debug_info = c_vte_terminal_tilix_get_fold_debug_info;

static if (COMPILE_VTE_BACKGROUND_COLOR) {
	alias vte_terminal_get_color_background_for_draw = c_vte_terminal_get_color_background_for_draw;
}

shared static this() {
	Linker.link(vte_terminal_get_disable_bg_draw, "vte_terminal_get_disable_bg_draw", LIBRARY_VTE);
	Linker.link(vte_terminal_set_disable_bg_draw, "vte_terminal_set_disable_bg_draw", LIBRARY_VTE);
	Linker.link(vte_terminal_tilix_set_fold_state, "vte_terminal_tilix_set_fold_state", LIBRARY_VTE);
	Linker.link(vte_terminal_tilix_row_at_y, "vte_terminal_tilix_row_at_y", LIBRARY_VTE);
	Linker.link(vte_terminal_tilix_fold_header_at, "vte_terminal_tilix_fold_header_at", LIBRARY_VTE);
	Linker.link(vte_terminal_tilix_toggle_fold_at, "vte_terminal_tilix_toggle_fold_at", LIBRARY_VTE);
	Linker.link(vte_terminal_tilix_get_fold_debug_info, "vte_terminal_tilix_get_fold_debug_info", LIBRARY_VTE);

	static if (COMPILE_VTE_BACKGROUND_COLOR) {
		Linker.link(vte_terminal_get_color_background_for_draw, "vte_terminal_get_color_background_for_draw", LIBRARY_VTE);
	}
}
