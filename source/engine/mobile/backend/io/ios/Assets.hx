package mobile.backend.io.ios;

#if ios
import cpp.UInt8;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import sys.FileStat;

@:cppFileCode('
#ifndef INCLUDED_Date
#include <Date.h>
#endif
#include <CoreFoundation/CoreFoundation.h>
#include <sys/stat.h>
#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <vector>
#include <string>
')
@:cppNamespaceCode('''
static const std::string& getBundleResourcePath()
{
	static std::string cached;
	static bool resolved = false;
	if (resolved)
		return cached;

	CFBundleRef bundle = CFBundleGetMainBundle();
	if (bundle)
	{
		CFURLRef url = CFBundleCopyResourcesDirectoryURL(bundle);
		if (url)
		{
			char path[PATH_MAX];
			if (CFURLGetFileSystemRepresentation(url, true, (UInt8*)path, (CFIndex)sizeof(path)))
				cached = path;
			CFRelease(url);
		}
	}
	resolved = true;
	return cached;
}

static std::string resolveAssetPath(const char* logicalPath)
{
	const std::string& base = getBundleResourcePath();
	if (base.empty())
		return std::string();
	// avoiding double-slash if logicalPath already starts
	if (logicalPath[0] == '/')
		return base + logicalPath;
	return base + "/" + logicalPath;
}

bool Assets_obj::native_exists(::String path)
{
	hx::EnterGCFreeZone();
	std::string fullPath = resolveAssetPath(path.__s);
	bool exists = false;
	if (!fullPath.empty())
	{
		struct stat st;
		exists = (stat(fullPath.c_str(), &st) == 0);
	}
	hx::ExitGCFreeZone();
	return exists;
}

::String Assets_obj::native_getContent(::String file)
{
	hx::EnterGCFreeZone();
	std::string fullPath = resolveAssetPath(file.__s);
	std::vector<char> buffer;
	bool failed = true;

	if (!fullPath.empty())
	{
		int fd = open(fullPath.c_str(), O_RDONLY | O_CLOEXEC);
		if (fd >= 0)
		{
			struct stat st;
			if (fstat(fd, &st) == 0 && S_ISREG(st.st_mode))
			{
				off_t len = st.st_size;
				if (len == 0)
				{
					failed = false; // valid empty file
				}
				else
				{
					buffer.resize((size_t)len);
					ssize_t totalRead = 0;
					while (totalRead < (ssize_t)len)
					{
						ssize_t n = read(fd, &buffer[totalRead], (size_t)(len - totalRead));
						if (n <= 0) { buffer.clear(); break; }
						totalRead += n;
					}
					if (totalRead == (ssize_t)len)
						failed = false;
				}
			}
			close(fd);
		}
	}

	hx::ExitGCFreeZone();

	if (failed)
		return ::String(null());
	if (buffer.empty())
		return ::String::emptyString;
	return ::String::create(&buffer[0], (int)buffer.size());
}

Array<unsigned char> Assets_obj::native_getBytes(::String file)
{
	hx::EnterGCFreeZone();
	std::string fullPath = resolveAssetPath(file.__s);
	off_t len = -1;
	bool isFile = false;

	if (!fullPath.empty())
	{
		struct stat st;
		if (stat(fullPath.c_str(), &st) == 0 && S_ISREG(st.st_mode))
		{
			len = st.st_size;
			isFile = true;
		}
	}
	hx::ExitGCFreeZone();

	if (!isFile)
		return null();

	if (len == 0)
		return Array_obj<unsigned char>::__new(0, 0);

	Array<unsigned char> result = Array_obj<unsigned char>::__new((int)len, (int)len);

	hx::EnterGCFreeZone();
	int fd = open(fullPath.c_str(), O_RDONLY | O_CLOEXEC);
	bool readOk = false;

	if (fd >= 0)
	{
		ssize_t totalRead = 0;
		while (totalRead < (ssize_t)len)
		{
			ssize_t n = read(fd, result->getBase() + totalRead, (size_t)(len - totalRead));
			if (n <= 0) break;
			totalRead += n;
		}
		readOk = (totalRead == (ssize_t)len);
		close(fd);
	}
	hx::ExitGCFreeZone();

	return readOk ? result : null();
}

bool Assets_obj::native_isDirectory(::String path)
{
	hx::EnterGCFreeZone();
	std::string fullPath = resolveAssetPath(path.__s);
	bool isDir = false;
	if (!fullPath.empty())
	{
		struct stat st;
		if (stat(fullPath.c_str(), &st) == 0)
			isDir = S_ISDIR(st.st_mode);
	}
	hx::ExitGCFreeZone();
	return isDir;
}

Array<::String> Assets_obj::native_readDirectory(::String path)
{
	hx::EnterGCFreeZone();
	std::string fullPath = resolveAssetPath(path.__s);
	std::vector<std::string> names;

	if (!fullPath.empty())
	{
		DIR* dir = opendir(fullPath.c_str());
		if (dir)
		{
			struct dirent* entry;
			while ((entry = readdir(dir)) != NULL)
			{
				const char* name = entry->d_name;
				if (name[0] == '.' && (name[1] == '\0' || (name[1] == '.' && name[2] == '\0')))
					continue;
				names.push_back(name);
			}
			closedir(dir);
		}
	}
	hx::ExitGCFreeZone();

	Array<::String> result = Array_obj<::String>::__new(0, 0);
	for (size_t i = 0; i < names.size(); i++)
		result->push(::String(names[i].c_str()));
	return result;
}

::Dynamic Assets_obj::native_stat(::String path)
{
	hx::EnterGCFreeZone();
	std::string fullPath = resolveAssetPath(path.__s);
	bool found = false;
	struct stat st;
	memset(&st, 0, sizeof(st));
	if (!fullPath.empty())
		found = (stat(fullPath.c_str(), &st) == 0);
	hx::ExitGCFreeZone();

	hx::Anon anon = hx::Anon_obj::Create();
	int mode = !found ? 0 : (S_ISDIR(st.st_mode) ? 0x4000 : 0x8000);

	anon->Add(HX_CSTRING("gid"),   found ? (int)st.st_gid   : 0);
	anon->Add(HX_CSTRING("uid"),   found ? (int)st.st_uid   : 0);
	anon->Add(HX_CSTRING("atime"), ::Date_obj::fromTime(found ? (double)st.st_atime * 1000.0 : 0.0));
	anon->Add(HX_CSTRING("mtime"), ::Date_obj::fromTime(found ? (double)st.st_mtime * 1000.0 : 0.0));
	anon->Add(HX_CSTRING("ctime"), ::Date_obj::fromTime(found ? (double)st.st_ctime * 1000.0 : 0.0));
	anon->Add(HX_CSTRING("size"),  found ? (int)st.st_size  : 0);
	anon->Add(HX_CSTRING("dev"),   found ? (int)st.st_dev   : 0);
	anon->Add(HX_CSTRING("ino"),   found ? (int)st.st_ino   : 0);
	anon->Add(HX_CSTRING("nlink"), found ? (int)st.st_nlink : 0);
	anon->Add(HX_CSTRING("rdev"),  found ? (int)st.st_rdev  : 0);
	anon->Add(HX_CSTRING("mode"),  mode);
	return anon;
}
''')
@:headerClassCode('
	static bool native_exists(::String path);
	static ::String native_getContent(::String file);
	static Array<unsigned char> native_getBytes(::String file);
	static bool native_isDirectory(::String path);
	static Array<::String> native_readDirectory(::String path);
	static ::Dynamic native_stat(::String path);
')
class Assets
{
	public static function getContent(file:String):String
	{
		final content:String = __getContent(file);

		if (content == null)
			throw 'file_contents, $file';

		return content;
	}

	public static function getBytes(file:String):Bytes
	{
		final data:Array<UInt8> = __getBytes(file);

		if (data == null)
			throw 'file_contents, $file';

		return Bytes.ofData(data);
	}

	public static function read(file:String, ?binary:Bool):BytesInput
	{
		return new BytesInput(getBytes(file));
	}

	public static function exists(path:String):Bool
	{
		return __exists(path);
	}

	public static function isDirectory(path:String):Bool
	{
		return __isDirectory(path);
	}

	public static function readDirectory(path:String):Array<String>
	{
		return __readDirectory(path);
	}

	public static function stat(path:String):FileStat
	{
		return __stat(path);
	}

	@:noCompletion
	@:native('mobile::backend::io::ios::Assets_obj::native_exists')
	private static function __exists(path:String):Bool
		return false;

	@:noCompletion
	@:native('mobile::backend::io::ios::Assets_obj::native_getContent')
	private static function __getContent(file:String):String
		return null;

	@:noCompletion
	@:native('mobile::backend::io::ios::Assets_obj::native_getBytes')
	private static function __getBytes(file:String):Array<UInt8>
		return null;

	@:noCompletion
	@:native('mobile::backend::io::ios::Assets_obj::native_isDirectory')
	private static function __isDirectory(path:String):Bool
		return false;

	@:noCompletion
	@:native('mobile::backend::io::ios::Assets_obj::native_readDirectory')
	private static function __readDirectory(path:String):Array<String>
		return null;

	@:noCompletion
	@:native('mobile::backend::io::ios::Assets_obj::native_stat')
	private static function __stat(path:String):Dynamic
		return null;
}
#end
