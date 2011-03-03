package org.spread_osd;

import java.util.Map;
import org.msgpack.template.FieldOption;
import org.msgpack.annotation.MessagePackMessage;

@MessagePackMessage(FieldOption.NULLABLE)
public class StoredObject {
	public byte[] data;
	public Map<String, String> attributes;

	public StoredObject() {
	}

	public boolean isFound() {
		return data != null && attributes != null;
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

