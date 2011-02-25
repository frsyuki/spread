package org.spread_osd;

import java.util.Map;
import org.msgpack.annotation.MessagePackMessage;

@MessagePackMessage
public class StoredObject {
	public byte[] data;
	public Map<String, String> attributes;

	public StoredObject() {
	}

	public StoredObject(byte[] data, Map<String, String> attributes) {
		this.data = data;
		this.attributes = attributes;
	}

	public byte[] getData() {
		return data;
	}

	public Map<String, String> getAttributes() {
		return attributes;
	}
}

