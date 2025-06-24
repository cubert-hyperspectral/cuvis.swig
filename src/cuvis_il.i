 
%ignore cuvis_version;
%ignore cuvis_measurement_get_data_info;
%ignore cuvis_measurement_get_data_string;
%ignore cuvis_comp_pixel_format_get;
%ignore cuvis_comp_available_pixel_format_get;

//%ignore cuvis_register_external_event_callback;
//%ignore cuvis_unregister_event_callback;

%module cuvis_il

/*


#if defined(SWIGCSHARP)



%include "std_wstring.i"
%include wchar.i
%include "typemaps.i"

%typemap(cstype) std::wstring  "Test1"
%typemap(imtype) std::wstring "Test2"


#endif
*/

#if defined(SWIGCSHARP)
%include windows.i
%include stl.i
%include callback.i

%include "std_wstring.i"
%include wchar.i
%include "typemaps.i"

//%typemap(log_message) std::wstring  "global::System.IntPtr"
//%typemap(log_message) std::wstring  "Test3"

%typemap(cstype) wchar_t const* "string"
%typemap(imtype) wchar_t const* "global::System.IntPtr"


/*
%inline  %{
SDK_CAPI CUVIS_STATUS SDK_CCALL
    cuvis_register_log_callback(log_callback i_callback, CUVIS_INT i_min_level);
SDK_CAPI CUVIS_STATUS SDK_CCALL cuvis_reset_log_callback();

%}
*/

%cs_callback(external_event_callback,cuvis_il.EventCallback);

//%cs_callback(log_callback, cuvis.LogCallback);
%cs_callback(log_callback_localized, cuvis_il.LogCallbackLocalized);




%pragma(csharp) modulecode=%{
public delegate void EventCallback(int handler_id, int event_id);
//public delegate void LogCallback(log_message message, int level);
public delegate void LogCallbackLocalized(System.IntPtr message, int level);
%}
#endif

 %{
  #define SWIG_FILE_WITH_INIT
 /* Includes the header in the wrapper code */
  #include "cuvis.h"
  #include <stdint.h>		// Use the C99 official header
  #include <utility>
  #include <string>
  #include <stdexcept>
  #include <cstring>


 %}


%inline  %{
char const* cuvis_version_swig()
{
	//avoid dangling pointer (invalid pointer) when returnging c_str
	static std::string version;
	CUVIS_CHAR buf[CUVIS_MAXBUF];
	
	auto status = cuvis_version(buf);
	if (status != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	version = std::string(buf);
	
	return version.c_str();
}

char const* cuvis_calib_get_id_swig(
    CUVIS_CALIB i_calib)
{
	//avoid dangling pointer (invalid pointer) when returnging c_str
	static std::string ID;
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	auto status = cuvis_calib_get_id(
	 i_calib
	 , buf
	);

	if (status != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	ID = std::string(buf);

	return ID.c_str();
}

char const* cuvis_session_file_get_hash_swig(
    CUVIS_SESSION_FILE i_session)
{
	//avoid dangling pointer (invalid pointer) when returnging c_str
	static std::string hash;
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	auto status = cuvis_session_file_get_hash(
	 i_session
	 , buf
	);

	if (status != status_ok)
	{
		if (status == status_not_available)
		{
			buf[0] = '\0';
		} else {
		throw std::invalid_argument(cuvis_get_last_error_msg());
		}
	}

	hash = std::string(buf);

	return hash.c_str();
}

char const* cuvis_measurement_get_calib_id_swig(
    CUVIS_MESU i_mesu)
{
	//avoid dangling pointer (invalid pointer) when returnging c_str
	static std::string ID;
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	auto status = cuvis_measurement_get_calib_id(
	 i_mesu
	 , buf
	);

	if (status != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	ID = std::string(buf);

	return ID.c_str();
}

char const* cuvis_proc_cont_get_calib_id_swig(
    CUVIS_PROC_CONT i_procCont)
{
	//avoid dangling pointer (invalid pointer) when returnging c_str
	static std::string ID;
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	auto status = cuvis_proc_cont_get_calib_id(
	 i_procCont
	 , buf
	);

	if (status != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	ID = std::string(buf);

	return ID.c_str();
}

char const* cuvis_measurement_get_data_info_swig(
    CUVIS_MESU i_mesu,
    CUVIS_DATA_TYPE* o_pType,
    CUVIS_INT i_id)
{
	//avoid dangling pointer (invalid pointer) when returnging c_str
	static std::string key;
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	auto status = cuvis_measurement_get_data_info(
	 i_mesu
	 , buf
	 , o_pType
	 , i_id
	);

	if (status != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	key = std::string(buf);

	return key.c_str();
}

char const* cuvis_measurement_get_data_string_swig(
    CUVIS_MESU i_mesu, const CUVIS_CHAR* i_key)
{
	//avoid dangling pointer (invalid pointer) when returnging c_str
	static std::string value;
	CUVIS_CHAR buf[CUVIS_MAXBUF*8];

	auto status = cuvis_measurement_get_data_string(
	 i_mesu
	 , i_key
	 , CUVIS_MAXBUF*8
	 , buf
	);

	if (status != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	value = std::string(buf);

	return value.c_str();
}

char const* cuvis_comp_pixel_format_get_swig(
    CUVIS_ACQ_CONT i_acqCont, CUVIS_INT i_id)
{
	//avoid dangling pointer (invalid pointer) when returnging c_str
	static std::string value;
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	auto status = cuvis_comp_pixel_format_get(i_acqCont, i_id, buf);

	if (status != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	value = std::string(buf);

	return value.c_str();
}

char const* cuvis_comp_available_pixel_format_get_swig(
    CUVIS_ACQ_CONT i_acqCont, CUVIS_INT i_id, CUVIS_INT i_index)
{
	//avoid dangling pointer (invalid pointer) when returnging c_str
	static std::string value;
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	auto status = cuvis_comp_available_pixel_format_get(i_acqCont, i_id, i_index, buf);

	if (status != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	value = std::string(buf);

	return value.c_str();
}
/*
bool p_unsigned_int_notnull(unsigned int * ptr)
{
	return (ptr == nullptr);
}
*/
%}

  
 /* Parse the header file to generate wrappers */

%include swigarch.i
%include wchar.i
%include cpointer.i



/* Exact integral types.  */

/* Signed.  */

typedef signed char		int8_t;
typedef short int		int16_t;
typedef int			int32_t;
#if defined(SWIGWORDSIZE64)
typedef long int		int64_t;
#else
typedef long long int		int64_t;
#endif

/* Unsigned.  */
typedef unsigned char		uint8_t;
typedef unsigned short int	uint16_t;
typedef unsigned int		uint32_t;
#if defined(SWIGWORDSIZE64)
typedef unsigned long int	uint64_t;
#else
typedef unsigned long long int	uint64_t;
#endif


/* Small types.  */

/* Signed.  */
typedef signed char		int_least8_t;
typedef short int		int_least16_t;
typedef int			int_least32_t;
#if defined(SWIGWORDSIZE64)
typedef long int		int_least64_t;
#else
typedef long long int		int_least64_t;
#endif

/* Unsigned.  */
typedef unsigned char		uint_least8_t;
typedef unsigned short int	uint_least16_t;
typedef unsigned int		uint_least32_t;
#if defined(SWIGWORDSIZE64)
typedef unsigned long int	uint_least64_t;
#else
typedef unsigned long long int	uint_least64_t;
#endif


/* Fast types.  */

/* Signed.  */
typedef signed char		int_fast8_t;
#if defined(SWIGWORDSIZE64)
typedef long int		int_fast16_t;
typedef long int		int_fast32_t;
typedef long int		int_fast64_t;
#else
typedef int			int_fast16_t;
typedef int			int_fast32_t;
typedef long long int		int_fast64_t;
#endif

/* Unsigned.  */
typedef unsigned char		uint_fast8_t;
#if defined(SWIGWORDSIZE64)
typedef unsigned long int	uint_fast16_t;
typedef unsigned long int	uint_fast32_t;
typedef unsigned long int	uint_fast64_t;
#else
typedef unsigned int		uint_fast16_t;
typedef unsigned int		uint_fast32_t;
typedef unsigned long long int	uint_fast64_t;
#endif


/* Types for `void *' pointers.  */
#if defined(SWIGWORDSIZE64)
typedef long int		intptr_t;
typedef unsigned long int	uintptr_t;
#else
typedef int			intptr_t;
typedef unsigned int		uintptr_t;
#endif


/* Largest integral types.  */
#if defined(SWIGWORDSIZE64)
typedef long int		intmax_t;
typedef unsigned long int	uintmax_t;
#else
typedef long long int		intmax_t;
typedef unsigned long long int	uintmax_t;
#endif


%include cpointer.i
%pointer_functions(int, p_int);
%pointer_functions(unsigned long long, p_ulong);
//%pointer_functions(unsigned int, p_unsigned_int);
//%pointer_functions(unsigned char, p_unsigned_char);
%pointer_functions(double, p_double);



%include carrays.i
%array_functions(unsigned char, p_unsigned_char);
%array_functions(unsigned int, p_unsigned_int);

#if defined(SWIGCSHARP)


#else
%include numpy.i
%init %{
import_array();
%}

%apply (unsigned char** ARGOUTVIEWM_ARRAY3, int * DIM1, int * DIM2, int * DIM3) {(unsigned char ** ptr, int * X, int * Y, int * Z)};
%apply (unsigned short int** ARGOUTVIEWM_ARRAY3, int * DIM1, int * DIM2, int * DIM3) {(unsigned short int ** ptr, int * X, int * Y, int * Z)};
%apply (unsigned int** ARGOUTVIEWM_ARRAY3, int * DIM1, int * DIM2, int * DIM3) {(unsigned int ** ptr, int * X, int * Y, int * Z)};
%apply (float** ARGOUTVIEWM_ARRAY3, int * DIM1, int * DIM2, int * DIM3) {(float ** ptr, int * X, int * Y, int * Z)};
%apply (unsigned short int *ARGOUT_ARRAY1, int DIM1) { (unsigned short int *data, int n) };

%inline  %{
void cuvis_read_imbuf_uint8(struct cuvis_imbuffer_t imbuf, unsigned char ** ptr, int * X, int * Y, int * Z)
{
	auto len = imbuf.width*imbuf.height*imbuf.channels;
	*ptr = new unsigned char [len];
	std::memcpy(*ptr,imbuf.raw,len*sizeof(unsigned char));

	*Y = (int)imbuf.width;
	*X = (int)imbuf.height;
	*Z = (int)imbuf.channels;
}
void cuvis_read_imbuf_uint16(struct cuvis_imbuffer_t imbuf, unsigned short int ** ptr, int * X, int * Y, int * Z)
{
	auto len = imbuf.width*imbuf.height*imbuf.channels;
	*ptr = new unsigned short int [len];
	std::memcpy(*ptr,imbuf.raw,len*sizeof(unsigned short int));


	*Y = (int)imbuf.width;
	*X = (int)imbuf.height;
	*Z = (int)imbuf.channels;
}

void cuvis_read_imbuf_uint32(struct cuvis_imbuffer_t imbuf, unsigned int ** ptr, int * X, int * Y, int * Z)
{
	auto len = imbuf.width*imbuf.height*imbuf.channels;
	*ptr = new unsigned int [len];
	std::memcpy(*ptr,imbuf.raw,len*sizeof(unsigned int));

	*Y = (int)imbuf.width;
	*X = (int)imbuf.height;
	*Z = (int)imbuf.channels;
}

void cuvis_read_imbuf_float32(struct cuvis_imbuffer_t imbuf, float ** ptr, int * X, int * Y, int * Z)
{
	auto len = imbuf.width*imbuf.height*imbuf.channels;
	*ptr = new float [len];
	std::memcpy(*ptr,imbuf.raw,len*sizeof(float));

	*Y = (int)imbuf.width;
	*X = (int)imbuf.height;
	*Z = (int)imbuf.channels;
}


%}

#endif

%include "cuvis.h"


%pointer_functions(enum cuvis_data_type_t, p_cuvis_data_type_t); 
%pointer_functions(enum cuvis_operation_mode_t, p_cuvis_operation_mode_t);
%pointer_functions(enum cuvis_hardware_state_t, p_cuvis_hardware_state_t);
%pointer_functions(enum cuvis_status_t, p_cuvis_status_t);
%pointer_functions(struct cuvis_worker_state_t, p_cuvis_worker_state_t);

