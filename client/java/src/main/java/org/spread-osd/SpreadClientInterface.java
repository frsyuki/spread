package org.spread_osd;

import java.util.Map;
import org.msgpack.rpc.Future;

public interface SpreadClientInterface {
	StoredObject get(String key);
	byte[] get_data(String key);
	Map<String, String> get_attrs(String key);
	byte[] read(String key, int offset, int size);

	StoredObject gett(int vtime, String key);
	byte[] gett_data(int vtime, String key);
	Map<String, String> gett_attrs(int vtime, String key);
	byte[] readt(int vtime, String key, int offset, int size);

	StoredObject getv(String vname, String key);
	byte[] getv_data(String vname, String key);
	Map<String, String> getv_attrs(String vname, String key);
	byte[] readv(String vname, String key, int offset, int size);

	ObjectKey add(String key, byte[] data, Map<String, String> attributes);
	ObjectKey add_data(String key, byte[] data);
	ObjectKey addv(String vname, String key, Map<String, String> attributes);
	ObjectKey addv_data(String key, byte[] data);

	boolean delete(String key);
	boolean deletet(int vtime, String key);
	boolean deletev(String vname, String key);

	boolean remove(String key);

	ObjectKey update_attrs(String key, Map<String, String> attributes);

	byte[] getd_data(ObjectKey okey);
	byte[] readd(ObjectKey okey, int offset, int size);


	Future<StoredObject> getAsync(String key);
	Future<byte[]> get_dataAsync(String key);
	Future<Map<String, String>> get_attrsAsync(String key);
	Future<byte[]> readAsync(String key, int offset, int size);

	Future<StoredObject> gettAsync(int vtime, String key);
	Future<byte[]> gett_dataAsync(int vtime, String key);
	Future<Map<String, String>> gett_attrsAsync(int vtime, String key);
	Future<byte[]> readtAsync(int vtime, String key, int offset, int size);

	Future<StoredObject> getvAsync(String vname, String key);
	Future<byte[]> getv_dataAsync(String vname, String key);
	Future<Map<String, String>> getv_attrsAsync(String vname, String key);
	Future<byte[]> readvAsync(String vname, String key, int offset, int size);

	Future<ObjectKey> addAsync(String key, byte[] data, Map<String, String> attributes);
	Future<ObjectKey> add_dataAsync(String key, byte[] data);
	Future<ObjectKey> addvAsync(String vname, String key, Map<String, String> attributes);
	Future<ObjectKey> addv_dataAsync(String key, byte[] data);

	Future<Boolean> deleteAsync(String key);
	Future<Boolean> deletetAsync(int vtime, String key);
	Future<Boolean> deletevAsync(String vname, String key);

	Future<Boolean> removeAsync(String key);

	Future<ObjectKey> update_attrsAsync(String key, Map<String, String> attributes);

	Future<byte[]> getd_dataAsync(ObjectKey okey);
	Future<byte[]> readdAsync(ObjectKey okey, int offset, int size);
}

