//
// MessagePack-RPC for Java
//
// Copyright (C) 2010-2011 FURUHASHI Sadayuki
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
//
package org.spread_osd;

import org.msgpack.*;
import org.msgpack.object.*;
import org.msgpack.rpc.*;
import org.msgpack.rpc.dispatcher.*;
import org.msgpack.rpc.config.*;
import org.msgpack.rpc.loop.*;
import org.msgpack.rpc.loop.netty.*;
import java.util.*;
import java.net.*;
import junit.framework.*;
import org.junit.Test;
import org.junit.After;
import org.junit.Before;
import static org.junit.Assert.*;

public class InterfaceTest extends TestCase {
	private String host;
	private int port;

	public InterfaceTest() {
		this.host = System.getProperty("HOST", "127.0.0.1");
		this.port = Integer.parseInt(System.getProperty("PORT", "49800"));
	}

	@Test
	public void testAddGetDelete() throws UnknownHostException {
		SpreadClient client = new SpreadClient(host, port);
		try {
			String key = "key1";

			byte[] data = "v1".getBytes();

			Map<String, String> attrs = new HashMap<String, String>();
			attrs.put("a1", "x1");
			attrs.put("a2", "x2");
			attrs.put("a3", "x3");

			ObjectKey okey = client.add(key, data, attrs);

			StoredObject rsobj = client.get(key);
			assertTrue(rsobj.isFound());
			assertArrayEquals(data, rsobj.getData());
			assertEquals(attrs, rsobj.getAttributes());

			byte[] rdata = client.get_data(key);
			assertArrayEquals(data, rdata);

			Map<String, String> rattrs = client.get_attrs(key);
			assertEquals(attrs, rattrs);

			byte[] rdata2 = client.getd_data(okey);
			assertArrayEquals(data, rdata2);

			boolean deleted = client.remove(key);
			assertTrue(deleted);

			StoredObject rsobj2 = client.get(key);
			assertFalse(rsobj2.isFound());

		} finally {
			client.close();
		}
	}
}

