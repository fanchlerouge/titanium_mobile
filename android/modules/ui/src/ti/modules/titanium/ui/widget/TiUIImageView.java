/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package ti.modules.titanium.ui.widget;

import java.io.IOException;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.atomic.AtomicBoolean;

import org.appcelerator.titanium.TiBlob;
import org.appcelerator.titanium.TiContext;
import org.appcelerator.titanium.TiDict;
import org.appcelerator.titanium.TiProxy;
import org.appcelerator.titanium.TiContext.OnLifecycleEvent;
import org.appcelerator.titanium.io.TiBaseFile;
import org.appcelerator.titanium.io.TiFileFactory;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.AsyncResult;
import org.appcelerator.titanium.util.Log;
import org.appcelerator.titanium.util.TiBackgroundImageLoadTask;
import org.appcelerator.titanium.util.TiConfig;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.util.TiUIHelper;
import org.appcelerator.titanium.view.TiUIView;

import ti.modules.titanium.filesystem.FileProxy;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.Handler;
import android.os.Message;

public class TiUIImageView extends TiUIView
	implements OnLifecycleEvent, Handler.Callback
{
	private static final String LCAT = "TiUIImageView";
	private static final boolean DBG = TiConfig.LOGD;

	private static final String EVENT_CLICK = "click";
	private static final int MAX_BITMAPS = 3;

	private Timer timer;
	//private AnimationTask animationTask;
	private Animator animator;
	private Object[] images;
	private Loader loader;
	private AtomicBoolean animating = new AtomicBoolean(false);
	private boolean reverse = false;
	private boolean paused = false;

	private class BgImageLoader extends TiBackgroundImageLoadTask
	{

		public BgImageLoader(TiContext tiContext, Integer imageWidth, Integer imageHeight) {
			super(tiContext, imageWidth, imageHeight);
		}

		@Override
		protected void onPostExecute(Drawable d) {
			super.onPostExecute(d);

			if (d != null) {
				TiImageView view = getView();
				if (view != null) {
					view.setImageDrawable(d, false);
				}
			}
		}
	}

	public TiUIImageView(TiViewProxy proxy) {
		super(proxy);

		if (DBG) {
			Log.d(LCAT, "Creating an ImageView");
		}

		TiImageView view = new TiImageView(proxy.getContext());
		setNativeView(view);
		proxy.getTiContext().addOnLifecycleEventListener(this);
	}

	private TiImageView getView() {
		return (TiImageView) nativeView;
	}

	public Bitmap createBitmap(Object image)
	{
		if (image instanceof TiBlob) {
			TiBlob blob = (TiBlob)image;
			return TiUIHelper.createBitmap(blob.getInputStream());
		} else if (image instanceof FileProxy) {
			FileProxy file = (FileProxy)image;
			try {
				return TiUIHelper.createBitmap(file.getBaseFile().getInputStream());
			} catch (IOException e) {
				Log.e(LCAT, "Error creating drawable from file: " + file.getBaseFile().getNativeFile().getName(), e);
			}
		} else if (image instanceof String) {
			String url = proxy.getTiContext().resolveUrl(null, (String)image);
			TiBaseFile file = TiFileFactory.createTitaniumFile(proxy.getTiContext(), new String[] { url }, false);
			try {
				return TiUIHelper.createBitmap(file.getInputStream());
			} catch (IOException e) {
				Log.e(LCAT, "Error creating drawable from path: " + image.toString(), e);
			}
		} else if (image instanceof TiDict) {
			TiBlob blob = TiUIHelper.getImageFromDict((TiDict)image);
			if (blob != null) {
				return TiUIHelper.createBitmap(blob.getInputStream());
			} else {
				Log.e(LCAT, "Couldn't find valid image in object: " + image.toString());
			}
		}
		return null;
	}
	
	private Handler handler = new Handler(this);
	private static final int SET_IMAGE = 10001;
	
	@Override
	public boolean handleMessage(Message msg) {
		if (msg.what == SET_IMAGE) {
			AsyncResult result = (AsyncResult)msg.obj;
			getView().setImageBitmap((Bitmap)result.getArg());
			result.setResult(null);
		}
		return false;
	}
	
	public void setImage(final Bitmap bitmap)
	{
		if (bitmap != null) {
			if (!proxy.getTiContext().isUIThread()) {
				Message msg = Message.obtain(handler, SET_IMAGE);
				AsyncResult result = new AsyncResult(bitmap);
				msg.obj = result;
				msg.sendToTarget();
				result.getResult();
			} else {
				getView().setImageBitmap(bitmap);
			}
		}
	}
	
	private class BitmapWithIndex {
		public BitmapWithIndex(Bitmap b, int i) {
			this.bitmap = b;
			this.index = i;
		}
		
		public Bitmap bitmap;
		public int index;
	}
	
	private class Loader implements Runnable
	{
		public static final int INFINITE = 0;
		
		private ArrayBlockingQueue<BitmapWithIndex> bitmapQueue;
		private int repeatIndex = 0;
		
		public Loader()
		{
			bitmapQueue = new ArrayBlockingQueue<BitmapWithIndex>(5);
		}
		
		private int getRepeatCount() {
			if (proxy.hasDynamicValue("repeatCount")) {
				return TiConvert.toInt(proxy.getDynamicValue("repeatCount"));
			}
			return INFINITE;
		}
		
		private boolean isRepeating()
		{
			int repeatCount = getRepeatCount();
			if (repeatCount <= INFINITE) {
				return true;
			}
			return repeatIndex < repeatCount;
		}
		
		private int getStart()
		{
			if (reverse) { return images.length-1; }
			return 0;
		}
		
		private boolean isNotFinalFrame(int frame)
		{
			if (reverse) { return frame >= 0; }
			return frame < images.length;
		}
		private int getCounter()
		{
			if (reverse) { return -1; }
			return 1;
		}
		
		public void run()
		{
			repeatIndex = 0;
			animating.set(true);
			boolean firedLoad = false;
			topLoop: while(isRepeating()) {
				long time = System.currentTimeMillis();
				for (int j = getStart(); isNotFinalFrame(j); j+=getCounter()) {
					if (bitmapQueue.size() == 5 && !firedLoad) {
						fireLoad("images");
						firedLoad = true;
					}
					while (paused) {
						try {
							Thread.sleep(200L);
						} catch (InterruptedException e) {
							e.printStackTrace();
						}
					}
					if (!animating.get()) {
						break topLoop;
					}
					Object image = images[j];
					Bitmap b = createBitmap(image);
					try {
						bitmapQueue.put(new BitmapWithIndex(b, j));
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
					repeatIndex++;
				}
				Log.d(LCAT, "TIME TO LOAD FRAMES: "+(System.currentTimeMillis()-time)+"ms");
			}
			animating.set(false);
		}
		
		public ArrayBlockingQueue<BitmapWithIndex> getBitmapQueue()
		{
			return bitmapQueue;
		}
	}

	public void setImages(final Object[] images)
	{
		if (images == null) return;
		
		TiUIImageView.this.images = images;
		loader = new Loader();
		Thread loaderThread = new Thread(loader);
		Log.d(LCAT, "STARTING LOADER THREAD "+loaderThread +" for "+this);
		loaderThread.start();
	}

	public double getDuration()
	{
		if (proxy.getDynamicValue("duration") != null) {
			return TiConvert.toDouble(proxy.getDynamicValue("duration"));
		}

		if (images != null) {
			return images.length * 33;
		}
		return 100;
	}

	private void fireLoad(String state)
	{
		TiDict data = new TiDict();
		data.put("state", state);
		proxy.fireEvent("load", data);
	}

	private void fireStart()
	{
		TiDict data = new TiDict();
		proxy.fireEvent("start", data);
	}

	private void fireChange(int index)
	{
		TiDict data = new TiDict();
		data.put("index", index);
		proxy.fireEvent("change", data);
	}

	private void fireStop()
	{
		TiDict data = new TiDict();
		proxy.fireEvent("stop", data);
	}

	private class Animator extends TimerTask
	{
		private Loader loader;
		
		public Animator(Loader loader)
		{
			this.loader = loader;
		}
		
		public void run()
		{
			try {
				BitmapWithIndex b = loader.getBitmapQueue().take();
				Log.d(LCAT, "set image: "+b.index);
				setImage(b.bitmap);
				fireChange(b.index);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
	}
	
	public void start()
	{
		if (!proxy.getTiContext().isUIThread()) {
			proxy.getTiContext().getActivity().runOnUiThread(new Runnable() {
				public void run() {
					handleStart();
				}
			});
		} else {
			handleStart();
		}
	}

	public void handleStart()
	{
		if (animator == null) {
			timer = new Timer();
			animator = new Animator(loader);

			int duration = (int) getDuration();
			timer.schedule(animator, duration, duration);
		} else {
			resume();
		}
	}

	public void pause()
	{
		paused = true;
	}

	public void resume()
	{
		paused = false;
	}

	public void stop()
	{
		if (timer != null) {
			timer.cancel();
		}
		timer = null;
		animator = null;
		animating.set(false);

		fireStop();
	}

	@Override
	public void processProperties(TiDict d)
	{
		TiImageView view = getView();

		if (d.containsKey("images")) {
			Object o = d.get("images");
			if (o instanceof Object[]) {
				setImages((Object[])o);
			}
		}
		else if (d.containsKey("url")) {
			new BgImageLoader(getProxy().getTiContext(), null, null).load(TiConvert.toString(d, "url"));
		}
		if (d.containsKey("canScale")) {
			view.setCanScaleImage(TiConvert.toBoolean(d, "canScale"));
		}
		if (d.containsKey("image")) {
			setImage(createBitmap(d.get("image")));
		} else {
			getProxy().internalSetDynamicValue("image", null, false);
		}
		
		super.processProperties(d);
	}

	@Override
	public void propertyChanged(String key, Object oldValue, Object newValue, TiProxy proxy)
	{
		TiImageView view = getView();

		if (key.equals("canScale")) {
			view.setCanScaleImage(TiConvert.toBoolean(newValue));
		} else if (key.equals("url")) {
			new BgImageLoader(getProxy().getTiContext(), null, null).load(TiConvert.toString(newValue));
		} else if (key.equals("image")) {
			setImage(createBitmap(newValue));
		} else if (key.equals("images")) {
			if (newValue instanceof Object[]) {
				setImages((Object[])newValue);
			}
		} else {
			super.propertyChanged(key, oldValue, newValue, proxy);
		}
	}


	public void onDestroy() {
	}

	public void onPause() {
		pause();
	}

	public void onResume() {
		resume();
	}

	public void onStart() {
	}

	public void onStop() {
		stop();
	}

	public boolean isAnimating() {
		return animating.get();
	}

	public boolean isReverse() {
		return reverse;
	}

	public void setReverse(boolean reverse) {
		this.reverse = reverse;
	}

	public TiBlob toBlob ()
	{
		Drawable drawable = getView().getImageDrawable();
		if (drawable != null && drawable instanceof BitmapDrawable) {
			Bitmap bitmap = ((BitmapDrawable)drawable).getBitmap();
			return TiBlob.blobFromImage(proxy.getTiContext(), bitmap);
		}

		return null;
	}
}
