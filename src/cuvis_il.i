 
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

#ifdef _WIN32
  #include <windows.h>
  #include <delayimp.h>
#endif

#ifndef CUVIS_BINDING_BUILT_VERSION
  #define CUVIS_BINDING_BUILT_VERSION "unknown"
#endif

/* A delay-loaded symbol that the DLL does not export raises an SEH exception and
   would kill the process. Convert it to a C++ throw, which %exception turns into
   a Python exception. MSVC forbids __try in a function that needs unwinding, so
   the throw lives in its own function. */
#if defined(_MSC_VER)
static void cuvis_dli_throw(bool proc_missing)
{
  throw std::runtime_error(
    proc_missing
      ? "cuvis: the loaded cuvis library does not export this function "
        "(the installed CUVIS SDK is older than the one this binding was built against)"
      : "cuvis: the cuvis library could not be loaded (it is missing, or one of its own "
        "dependencies such as the CUDA runtime cannot be found)");
}
template <class F> static void cuvis_seh_call(F&& f)
{
  bool proc_missing = false;
  __try { f(); }
  __except (((proc_missing = (GetExceptionCode() ==
                VcppException(ERROR_SEVERITY_ERROR, ERROR_PROC_NOT_FOUND))) ||
             GetExceptionCode() == VcppException(ERROR_SEVERITY_ERROR, ERROR_MOD_NOT_FOUND))
              ? EXCEPTION_EXECUTE_HANDLER : EXCEPTION_CONTINUE_SEARCH)
  { cuvis_dli_throw(proc_missing); }
}
#  define CUVIS_GUARD(code) cuvis_seh_call([&]{ code });
#else
#  define CUVIS_GUARD(code) code
#endif

#ifdef SWIGPYTHON
/* Idempotent, so the same statement serves both the catch blocks and the success path. */
#define CUVIS_REGAIN_GIL   do { if (_cuvis_thread) { PyEval_RestoreThread(_cuvis_thread); _cuvis_thread = NULL; } } while (0)
#endif

 %}

%inline %{
/* The one fact a caller cannot derive from the binary or from the loaded library: which
   cuvis library this binding was compiled against. Reported in the same form as
   cuvis_version(), so the two can be held side by side, which is what distinguishes "your
   SDK is older than this binding" and "your SDK is a different build of the same version"
   from "something else is wrong" when symbols resolve. */
const char* cuvis_built_against_version(void) { return CUVIS_BINDING_BUILT_VERSION; }
%}

// Without this, the throws in the helpers below unwind into the host runtime with no
// handler and call std::terminate.
%include exception.i
/* The GIL is released around every call into cuvis, so a blocking wait parks a thread
   instead of stopping the interpreter. It is released by hand rather than with SWIG's
   threads="1", whose guard is an RAII object: CUVIS_GUARD unwinds through SEH, and this
   is built /EHsc, under which MSVC does not run C++ destructors while unwinding an SEH
   exception. The guard would then never reacquire the GIL and SWIG_exception below would
   touch the Python C API without it, which is an access violation, not an exception.
   Restoring in each catch keeps that correct without depending on unwinding at all. */
#ifdef SWIGPYTHON
%exception {
  PyThreadState *_cuvis_thread = PyEval_SaveThread();
  try { CUVIS_GUARD($action) }
  catch (std::invalid_argument const& e) { CUVIS_REGAIN_GIL; SWIG_exception(SWIG_ValueError,   e.what()); }
  catch (std::exception const& e)        { CUVIS_REGAIN_GIL; SWIG_exception(SWIG_RuntimeError, e.what()); }
  catch (...)                            { CUVIS_REGAIN_GIL; SWIG_exception(SWIG_UnknownError, "unknown C++ exception from cuvis"); }
  CUVIS_REGAIN_GIL;
}
#else
%exception {
  try { CUVIS_GUARD($action) }
  catch (std::invalid_argument const& e) { SWIG_exception(SWIG_ValueError,   e.what()); }
  catch (std::exception const& e)        { SWIG_exception(SWIG_RuntimeError, e.what()); }
  catch (...)                            { SWIG_exception(SWIG_UnknownError, "unknown C++ exception from cuvis"); }
}
#endif


/* std::string rather than char const*: the previous form returned c_str() from a
   function-local static, which is one buffer shared by every thread in the process. The GIL
   was the only thing serialising it, so releasing the GIL made two callers overwrite each
   other and a third read a key that was not its own. Returning by value removes the shared
   buffer rather than making it per-thread, so a helper added later cannot reintroduce the
   race by forgetting an annotation. */
%include <std_string.i>

%inline  %{
std::string cuvis_version_swig()
{
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	if (cuvis_version(buf) != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	return buf;
}

std::string cuvis_calib_get_id_swig(
    CUVIS_CALIB i_calib)
{
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	if (cuvis_calib_get_id(i_calib, buf) != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	return buf;
}

std::string cuvis_session_file_get_hash_swig(
    CUVIS_SESSION_FILE i_session)
{
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	auto status = cuvis_session_file_get_hash(i_session, buf);

	if (status != status_ok)
	{
		/* An absent hash is reported as a status, not an error, and reads as empty. */
		if (status == status_not_available)
		{
			return std::string();
		}
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	return buf;
}

std::string cuvis_measurement_get_calib_id_swig(
    CUVIS_MESU i_mesu)
{
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	if (cuvis_measurement_get_calib_id(i_mesu, buf) != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	return buf;
}

std::string cuvis_proc_cont_get_calib_id_swig(
    CUVIS_PROC_CONT i_procCont)
{
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	if (cuvis_proc_cont_get_calib_id(i_procCont, buf) != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	return buf;
}

std::string cuvis_measurement_get_data_info_swig(
    CUVIS_MESU i_mesu,
    CUVIS_DATA_TYPE* o_pType,
    CUVIS_INT i_id)
{
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	if (cuvis_measurement_get_data_info(i_mesu, buf, o_pType, i_id) != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	return buf;
}

std::string cuvis_measurement_get_data_string_swig(
    CUVIS_MESU i_mesu, const CUVIS_CHAR* i_key)
{
	/* Sized from the SDK rather than from a fixed buffer. The CUVIS_MAXBUF*8 buffer this
	   replaced silently truncated longer values, and then read past its own end, because the
	   SDK writes no terminator when the value fills the buffer exactly: a 3232 byte
	   settings_rec came back as 2054 bytes ending in uninitialised stack. */
	CUVIS_SIZE length = 0;

	if (cuvis_measurement_get_data_string_length(i_mesu, i_key, &length) != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	std::string value;
	value.resize(length + 1);

	if (cuvis_measurement_get_data_string(i_mesu, i_key, length + 1, &value[0]) != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	value.resize(std::strlen(value.c_str()));

	return value;
}

std::string cuvis_comp_pixel_format_get_swig(
    CUVIS_ACQ_CONT i_acqCont, CUVIS_INT i_id)
{
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	if (cuvis_comp_pixel_format_get(i_acqCont, i_id, buf) != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	return buf;
}

std::string cuvis_comp_available_pixel_format_get_swig(
    CUVIS_ACQ_CONT i_acqCont, CUVIS_INT i_id, CUVIS_INT i_index)
{
	CUVIS_CHAR buf[CUVIS_MAXBUF];

	if (cuvis_comp_available_pixel_format_get(i_acqCont, i_id, i_index, buf) != status_ok)
	{
		throw std::invalid_argument(cuvis_get_last_error_msg());
	}

	return buf;
}
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
%apply (unsigned int** ARGOUTVIEWM_ARRAY1, int *  DIM1) { (unsigned int ** ptr, int * n) };

%inline  %{

void cuvis_read_calib_info_wl_vec(struct cuvis_calibration_info_t info,
                                  unsigned int **ptr,
                                  int *n)
{
	*ptr = new unsigned int [info.cube_channels];
	std::memcpy(*ptr,info.cube_wavelengths,info.cube_channels*sizeof(unsigned int));       
    *n    = (int)info.cube_channels;      
}


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

/* Reference spectra. Shims rather than direct wrapping: the C setters pair two arrays
   with one shared count, and the C getters use a size-query-then-copy protocol; numpy.i
   expresses neither directly. The buffers follow the cuvis_read_imbuf_* precedent:
   new[]ed here, owned by the returned numpy array. */
%apply (float* IN_ARRAY1, int DIM1) {(float* wls, int n_wls), (float* vals, int n_vals)};
%apply (unsigned short* IN_ARRAY1, int DIM1) {(unsigned short* counts, int n_counts)};
%apply (float** ARGOUTVIEWM_ARRAY1, int* DIM1) {(float** o_wls, int* o_n_wls), (float** o_vals, int* o_n_vals)};
%apply (unsigned short** ARGOUTVIEWM_ARRAY1, int* DIM1) {(unsigned short** o_counts, int* o_n_counts)};

%inline  %{

int cuvis_proc_cont_set_reference_spectrum_swig(int procCont, float* wls, int n_wls, float* vals, int n_vals)
{
	if (n_wls != n_vals || n_wls <= 0)
		return status_error;
	return cuvis_proc_cont_set_reference_spectrum(procCont, wls, vals, (uint32_t)n_wls);
}

int cuvis_proc_cont_set_reference_spectrum_counts_swig(
    int procCont, float* wls, int n_wls, unsigned short* counts, int n_counts, int effectiveBitDepth, double integrationTime, double loadLevel)
{
	if (n_wls != n_counts || n_wls <= 0)
		return status_error;
	return cuvis_proc_cont_set_reference_spectrum_counts(
	    procCont, wls, counts, (uint32_t)n_wls, (uint16_t)effectiveBitDepth, integrationTime, loadLevel);
}

int cuvis_proc_cont_get_reference_spectrum_swig(int procCont, float** o_wls, int* o_n_wls, float** o_vals, int* o_n_vals)
{
	uint32_t count = 0;
	auto status = cuvis_proc_cont_get_reference_spectrum_size(procCont, Reference_TargetSpectrum, &count);
	if (status != status_ok)
		count = 0;
	*o_wls = new float[count]();
	*o_vals = new float[count]();
	*o_n_wls = (int)count;
	*o_n_vals = (int)count;
	if (status == status_ok && count > 0)
		status = cuvis_proc_cont_get_reference_spectrum(procCont, *o_wls, *o_vals, count);
	return status;
}

int cuvis_proc_cont_get_reference_spectrum_counts_swig(int procCont, float** o_wls, int* o_n_wls, unsigned short** o_counts, int* o_n_counts)
{
	uint32_t count = 0;
	auto status = cuvis_proc_cont_get_reference_spectrum_size(procCont, Reference_WhiteSpectrum, &count);
	if (status != status_ok)
		count = 0;
	*o_wls = new float[count]();
	*o_counts = new unsigned short[count]();
	*o_n_wls = (int)count;
	*o_n_counts = (int)count;
	if (status == status_ok && count > 0)
		status = cuvis_proc_cont_get_reference_spectrum_counts(procCont, *o_wls, *o_counts, count);
	return status;
}

%}

#endif

%include "cuvis.h"


%pointer_functions(enum cuvis_data_type_t, p_cuvis_data_type_t);
%pointer_functions(enum cuvis_operation_mode_t, p_cuvis_operation_mode_t);
%pointer_functions(enum cuvis_hardware_state_t, p_cuvis_hardware_state_t);
%pointer_functions(enum cuvis_status_t, p_cuvis_status_t);
%pointer_functions(struct cuvis_worker_state_t, p_cuvis_worker_state_t);


