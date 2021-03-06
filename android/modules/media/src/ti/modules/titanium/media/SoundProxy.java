/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package ti.modules.titanium.media;

import org.appcelerator.titanium.TiContext;
import org.appcelerator.titanium.TiDict;
import org.appcelerator.titanium.TiProxy;
import org.appcelerator.titanium.TiContext.OnLifecycleEvent;
import org.appcelerator.titanium.util.Log;
import org.appcelerator.titanium.util.TiConfig;
import org.appcelerator.titanium.util.TiConvert;

import ti.modules.titanium.filesystem.FileProxy;

public class SoundProxy extends TiProxy
	implements OnLifecycleEvent
{
	private static final String LCAT = "SoundProxy";
	private static final boolean DBG = TiConfig.LOGD;

	protected TiSound snd;

	public SoundProxy(TiContext tiContext, Object[] args)
	{
		super(tiContext);

		if (args != null && args.length > 0) {
			TiDict options = (TiDict) args[0];
			if (options != null) {
				if (options.containsKey("url")) {
					internalSetDynamicValue("url", tiContext.resolveUrl(null, TiConvert.toString(options, "url")), false);
				} else if (options.containsKey("sound")) {
					FileProxy fp = (FileProxy) options.get("sound");
					if (fp != null) {
						String url = fp.getNativePath();
						internalSetDynamicValue("url", url, false);
					}
				}
				if (options.containsKey("allowBackground")) {
					internalSetDynamicValue("allowBackground", options.get("allowBackground"), false);
				}
				if (DBG) {
					Log.i(LCAT, "Creating sound proxy for url: " + TiConvert.toString(getDynamicValue("url")));
				}
			}
		}
		tiContext.addOnLifecycleEventListener(this);
		setDynamicValue("volume", 0.5);
	}

	public boolean isPlaying() {
		TiSound s = getSound();
		if (s != null) {
			return s.isPlaying();
		}
		return false;
	}

	public boolean isPaused() {
		TiSound s = getSound();
		if (s != null) {
			return s.isPaused();
		}
		return false;
	}

	public boolean isLooping() {
		TiSound s = getSound();
		if (s != null) {
			return s.isLooping();
		}
		return false;
	}

	public boolean getLooping() {
		TiSound s = getSound();
		if (s != null) {
			return s.isLooping();
		}
		return false;
	}

	public void setLooping(boolean looping) {
		TiSound s = getSound();
		if (s != null) {
			s.setLooping(looping);
		}
	}

	// An alias for play so that sound can be used instead of an audioplayer
	public void start() {
		play();
	}

	public void play() {
		TiSound s = getSound();
		if (s != null) {
			s.play();
		}
	}

	public void pause() {
		TiSound s = getSound();
		if (s != null) {
			s.pause();
		}
	}

	public void reset() {
		TiSound s = getSound();
		if (s != null) {
			s.reset();
		}
	}

	public void release() {
		TiSound s = getSound();
		if (s != null) {
			s.release();
			snd = null;
		}
	}

	public void destroy() {
		release();
	}

	public void stop() {
		TiSound s = getSound();
		if (s != null) {
			s.stop();
		}
	}

	public int getDuration() {
		TiSound s = getSound();
		if (s != null) {
			return s.getDuration();
		}

		return 0;
	}

	public int getTime() {
		TiSound s = getSound();
		if (s != null) {
			return s.getTime();
		}
		return 0;
	}

	public void setTime(Object pos) {
		if (pos != null) {
			TiSound s = getSound();
			if (s != null) {
				s.setTime(TiConvert.toInt(pos));
			}
		}
	}
	protected TiSound getSound()
	{
		if (snd == null) {
			snd = new TiSound(this);
			setModelListener(snd);
		}
		return snd;
	}

	private boolean allowBackground() {
		boolean allow = false;
		if (hasDynamicValue("allowBackground")) {
			allow = TiConvert.toBoolean(getDynamicValue("allowBackground"));
		}
		return allow;
	}

	public void onStart() {
	}

	public void onResume() {
		if (!allowBackground()) {
			if (snd != null) {
				snd.onResume();
			}
		}
	}

	public void onPause() {
		if (!allowBackground()) {
			if (snd != null) {
				snd.onPause();
			}
		}
	}

	public void onStop() {
	}

	public void onDestroy() {
		if (snd != null) {
			snd.onDestroy();
		}
		snd = null;
	}


}
