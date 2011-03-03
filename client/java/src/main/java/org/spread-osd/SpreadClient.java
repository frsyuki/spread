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

import java.net.InetSocketAddress;
import java.net.UnknownHostException;
import java.util.Map;
import org.msgpack.rpc.loop.EventLoop;
import org.msgpack.rpc.Client;
import org.msgpack.rpc.Future;

public class SpreadClient {
	private EventLoop loop;
	private Client client;
	private SpreadClientInterface proxy;

	public SpreadClient(String host, int port) throws UnknownHostException {
		this(new InetSocketAddress(host, port));
	}

	public SpreadClient(InetSocketAddress address) {
		this.loop = EventLoop.start();
		this.client = new Client(address, loop);
		this.proxy = client.proxy(SpreadClientInterface.class);
	}

	public void close() {
		client.close();
		loop.shutdown();
	}

	public StoredObject get(String key) {
		return proxy.get(key);
	}
	public byte[] get_data(String key) {
		return proxy.get_data(key);
	}
	public Map<String, String> get_attrs(String key) {
		return proxy.get_attrs(key);
	}
	public byte[] read(String key, int offset, int size) {
		return proxy.read(key, offset, size);
	}

	public StoredObject gett(int vtime, String key) {
		return proxy.gett(vtime, key);
	}
	public byte[] gett_data(int vtime, String key) {
		return proxy.gett_data(vtime, key);
	}
	public Map<String, String> gett_attrs(int vtime, String key) {
		return proxy.gett_attrs(vtime, key);
	}
	public byte[] readt(int vtime, String key, int offset, int size) {
		return proxy.readt(vtime, key, offset, size);
	}

	public StoredObject getv(String vname, String key) {
		return proxy.getv(vname, key);
	}
	public byte[] getv_data(String vname, String key) {
		return proxy.getv_data(vname, key);
	}
	public Map<String, String> getv_attrs(String vname, String key) {
		return proxy.getv_attrs(vname, key);
	}
	public byte[] readv(String vname, String key, int offset, int size) {
		return proxy.readv(vname, key, offset, size);
	}

	public ObjectKey add(String key, byte[] data, Map<String, String> attributes) {
		return proxy.add(key, data, attributes);
	}
	public ObjectKey add_data(String key, byte[] data) {
		return proxy.add_data(key, data);
	}
	public ObjectKey addv(String vname, String key, Map<String, String> attributes) {
		return proxy.addv(vname, key, attributes);
	}
	public ObjectKey addv_data(String key, byte[] data) {
		return proxy.addv_data(key, data);
	}

	public boolean delete(String key) {
		return proxy.delete(key);
	}
	public boolean deletet(int vtime, String key) {
		return proxy.deletet(vtime, key);
	}
	public boolean deletev(String vname, String key) {
		return proxy.deletev(vname, key);
	}

	public boolean remove(String key) {
		return proxy.remove(key);
	}

	public ObjectKey update_attrs(String key, Map<String, String> attributes) {
		return proxy.update_attrs(key, attributes);
	}

	public byte[] getd_data(ObjectKey okey) {
		return proxy.getd_data(okey);
	}
	public byte[] readd(ObjectKey okey, int offset, int size) {
		return proxy.readd(okey, offset, size);
	}

	public Future<StoredObject> getAsync(String key) {
		return proxy.getAsync(key);
	}
	public Future<byte[]> get_dataAsync(String key) {
		return proxy.get_dataAsync(key);
	}
	public Future<Map<String, String>> get_attrsAsync(String key) {
		return proxy.get_attrsAsync(key);
	}
	public Future<byte[]> readAsync(String key, int offset, int size) {
		return proxy.readAsync(key, offset, size);
	}

	public Future<StoredObject> gettAsync(int vtime, String key) {
		return proxy.gettAsync(vtime, key);
	}
	public Future<byte[]> gett_dataAsync(int vtime, String key) {
		return proxy.gett_dataAsync(vtime, key);
	}
	public Future<Map<String, String>> gett_attrsAsync(int vtime, String key) {
		return proxy.gett_attrsAsync(vtime, key);
	}
	public Future<byte[]> readtAsync(int vtime, String key, int offset, int size) {
		return proxy.readtAsync(vtime, key, offset, size);
	}

	public Future<StoredObject> getvAsync(String vname, String key) {
		return proxy.getvAsync(vname, key);
	}
	public Future<byte[]> getv_dataAsync(String vname, String key) {
		return proxy.getv_dataAsync(vname, key);
	}
	public Future<Map<String, String>> getv_attrsAsync(String vname, String key) {
		return proxy.getv_attrsAsync(vname, key);
	}
	public Future<byte[]> readvAsync(String vname, String key, int offset, int size) {
		return proxy.readvAsync(vname, key, offset, size);
	}

	public Future<ObjectKey> addAsync(String key, byte[] data, Map<String, String> attributes) {
		return proxy.addAsync(key, data, attributes);
	}
	public Future<ObjectKey> add_dataAsync(String key, byte[] data) {
		return proxy.add_dataAsync(key, data);
	}
	public Future<ObjectKey> addvAsync(String vname, String key, Map<String, String> attributes) {
		return proxy.addvAsync(vname, key, attributes);
	}
	public Future<ObjectKey> addv_dataAsync(String key, byte[] data) {
		return proxy.addv_dataAsync(key, data);
	}

	public Future<Boolean> deleteAsync(String key) {
		return proxy.deleteAsync(key);
	}
	public Future<Boolean> deletetAsync(int vtime, String key) {
		return proxy.deletetAsync(vtime, key);
	}
	public Future<Boolean> deletevAsync(String vname, String key) {
		return proxy.deletevAsync(vname, key);
	}

	public Future<Boolean> removeAsync(String key) {
		return proxy.removeAsync(key);
	}

	public Future<ObjectKey> update_attrsAsync(String key, Map<String, String> attributes) {
		return proxy.update_attrsAsync(key, attributes);
	}

	public Future<byte[]> getd_dataAsync(ObjectKey okey) {
		return proxy.getd_dataAsync(okey);
	}
	public Future<byte[]> readdAsync(ObjectKey okey, int offset, int size) {
		return proxy.readdAsync(okey, offset, size);
	}
}

