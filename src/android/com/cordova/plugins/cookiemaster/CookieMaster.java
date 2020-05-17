package com.cordova.plugins.cookiemaster;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

import android.util.Log;

import java.net.HttpCookie;

import android.webkit.CookieManager;

public class CookieMaster extends CordovaPlugin {

    private final String TAG = "CookieMasterPlugin";
    public static final String ACTION_GET_COOKIES = "getCookies";
    public static final String ACTION_GET_COOKIE_VALUE = "getCookieValue";
    public static final String ACTION_SET_COOKIE_VALUE = "setCookieValue";
    public static final String ACTION_CLEAR_COOKIES = "clearCookies";
    public static final String ACTION_CLEAR_COOKIE = "clearCookie";

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {

        if (ACTION_GET_COOKIES.equals(action)) {
            return this.getCookies(args, callbackContext);
        }
        else if (ACTION_GET_COOKIE_VALUE.equals(action)) {
            return this.getCookie(args, callbackContext);

        } else if (ACTION_SET_COOKIE_VALUE.equals(action)) {
            return this.setCookie(args, callbackContext);
        } else if (ACTION_CLEAR_COOKIES.equals(action)) {
            return this.clearCookies(callbackContext);
        } else if (ACTION_CLEAR_COOKIE.equals(action)) {
            final String url = args.getString(0);
            final String cookieName = args.getString(1);

            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    try {
                        HttpCookie cookie = new HttpCookie(cookieName, "InvalidCookie");

                        String cookieString = cookie.toString().replace("\"", "");
                        CookieManager cookieManager = CookieManager.getInstance();
                        cookieManager.setCookie(url, cookieString);
                        cookieManager.flush(); // Sync the invalid cookie to persistent storage in order to overwrite the valid cookie.

                        PluginResult res = new PluginResult(PluginResult.Status.OK, "Successfully cleared cookie");
                        callbackContext.sendPluginResult(res);
                    } catch (Exception e) {
                        Log.e(TAG, "Exception: " + e.getMessage());
                        callbackContext.error(e.getMessage());
                    }
                }
            });
            return true;
        }

        callbackContext.error("Invalid action");
        return false;

    }

    /**
     * returns cookies for given url
     * @param args
     * @param callbackContext
     * @return
     */
    private boolean getCookies(JSONArray args, final CallbackContext callbackContext) {
        try {
            final String url = args.getString(0);

            cordova
                    .getThreadPool()
                    .execute(new Runnable() {
                        public void run() {
                            try {
                                CookieManager cookieManager = CookieManager.getInstance();
                                String[] cookies = cookieManager.getCookie(url).split("; ");
                                String cookieValue = "";

                                JSONStringer json = new JSONStringer();
                                json.object();
                                for (String c : cookies) {
                                    String[] cookie = c.split("=");
                                    json.key(cookie[0].trim());
                                    json.value(cookie[1].trim());
                                }
                                json.endObject();

                                if (json != null) {
                                    PluginResult res = new PluginResult(PluginResult.Status.OK, json.toString());
                                    callbackContext.sendPluginResult(res);
                                }
                                else {
                                    callbackContext.error("Cookie not found!");
                                }
                            }
                            catch (Exception e) {
                                Log.e(TAG, "Exception: " + e.getMessage());
                                callbackContext.error(e.getMessage());
                            }
                        }
                    });

            return true;
        }
        catch(JSONException e) {
            callbackContext.error("JSON parsing error");
        }

        return false;
    }

    /**
     * returns cookie under given key
     * @param args
     * @param callbackContext
     * @return
     */
    private boolean getCookie(JSONArray args, final CallbackContext callbackContext) {
        try {
            final String url = args.getString(0);
            final String cookieName = args.getString(1);

            cordova
                    .getThreadPool()
                    .execute(new Runnable() {
                        public void run() {
                            try {
                                CookieManager cookieManager = CookieManager.getInstance();
                                String[] cookies = cookieManager.getCookie(url).split("; ");
                                String cookieValue = "";

                                for (int i = 0; i < cookies.length; i++) {
                                    if (cookies[i].contains(cookieName + "=")) {
                                        cookieValue = cookies[i].split("=")[1].trim();
                                        break;
                                    }
                                }

                                JSONObject json = null;

                                if (cookieValue != "") {
                                    json = new JSONObject("{cookieValue:\"" + cookieValue + "\"}");
                                }

                                if (json != null) {
                                    PluginResult res = new PluginResult(PluginResult.Status.OK, json);
                                    callbackContext.sendPluginResult(res);
                                }
                                else {
                                    callbackContext.error("Cookie not found!");
                                }
                            }
                            catch (Exception e) {
                                callbackContext.error(e.getMessage());
                            }
                        }
                    });

            return true;
        }
        catch(JSONException e) {
            callbackContext.error("JSON parsing error");
        }

        return false;
    }

    /**
     * sets cookie value under given key
     * @param args
     * @param callbackContext
     * @return boolean
     */
    private boolean setCookie(JSONArray args, final CallbackContext callbackContext) {
        try {
            final String url = args.getString(0);
            final String cookieName = args.getString(1);
            final String cookieValue = args.getString(2);

            cordova
                    .getThreadPool()
                    .execute(new Runnable() {
                        public void run() {
                            try {
                                CookieManager cookieManager = CookieManager.getInstance();
                                cookieManager.setCookie(url, cookieName + "=" + cookieValue);

                                PluginResult res = new PluginResult(PluginResult.Status.OK, "Successfully added cookie");
                                callbackContext.sendPluginResult(res);
                            }
                            catch (Exception e) {
                                callbackContext.error(e.getMessage());
                            }
                        }
                    });

            return true;
        }
        catch(JSONException e) {
            callbackContext.error("JSON parsing error");
        }

        return false;
    }

    private boolean clearCookies(final CallbackContext callbackContext) {
        CookieManager cookieManager = CookieManager.getInstance();

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                cookieManager.removeAllCookies(new ValueCallback<Boolean>() {
                    @Override
                    public void onReceiveValue(Boolean value) {}
                });

                cookieManager.flush();
            }
            else {
                cookieManager.removeAllCookie();
                cookieManager.removeSessionCookie();
            }

            callbackContext.success();
        }

        callbackContext.error("Invalid action");
        return false;
    }
}
