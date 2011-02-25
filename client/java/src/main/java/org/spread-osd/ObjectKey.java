package org.spread_osd;

import org.msgpack.annotation.MessagePackMessage;

@MessagePackMessage
public class ObjectKey {
	public String key;
	public int vtime;
	public int rsid;

	public ObjectKey() {
	}

	public ObjectKey(String key, int vtime, int rsid) {
		this.key = key;
		this.vtime = vtime;
		this.rsid = rsid;
	}

	public String getKey() {
		return key;
	}

	public int getVtime() {
		return vtime;
	}

	public int getRsid() {
		return rsid;
	}
}

