//////////////////////////////////////////////////////////////////////////
// cs_callback is used to marshall callbacks. It allows a C# function to
// be passed to C++ as a function pointer through P/Invoke, which has the
// ability to make unmanaged-to-managed thunks. It does NOT allow you to
// pass C++ function pointers to C#.
//
// Tested under:
// - C#: Visual Studio 2015
// - C++: Intel Parallel Studio 2017 SE
//
// Anyway, to use this macro you need to declare the function pointer type
// TYPE in the appropriate header file (including the calling convention),
// declare a delegate named after CSTYPE in your C# project, and use this
// macro in your .i file. Here is an example:
//
// C++: "callback.h":
//    #pragma once
//    typedef void(__stdcall *CppCallback)(int code, const char* message);
//    void call(CppCallback callback);
//
// C++: "callback.cpp":
//    #include "stdafx.h" // Only for precompiled headers.
//    #include "callback.h"
//    void call(CppCallback callback)
//    {
//        callback(1234, "Hello from C++");
//    }
//
// C#: Add this manually to C# code (it will not be auto-generated by SWIG):
//    public delegate void CSharpCallback(int code, string message);
//
// C#: Add this test method:
//    public class CallbackNUnit
//    {
//        public void Callback_Test()
//        {
//            MyModule.call((code, message) =>
//            {
//                // Prints "Hello from C++ 1234"
//                Console.WriteLine(code + " " + message);
//            });   
//        }        
//    }
//
// SWIG: In your .i file:
//   %module MyModule
//   %{
//     #include "callback.h"
//   %}
//   
//   %include <windows.i>
//   %include <stl.i>
//   
//   // Links typedef in C++ header file to manual delegate definition in C# file.
//   %include "callback.i" // The right spot for this file to be included!
//   %cs_callback(CppCallback, CSharpCallback)
//   #include "callback.h"
//
// As an alternative to specifying __stdcall on the C++ side, in the .NET
// Framework (but not the Compact Framework) you can use the following
// attribute on the C# delegate in order to get compatibility with the
// default calling convention of Visual C++ function pointers:
// [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
//
// Remember to invoke %cs_callback BEFORE any code involving Callback. 
//
// References: 
// - http://swig.10945.n7.nabble.com/C-Callback-Function-Implementation-td10853.html
// - http://.com/questions/23131583/proxying-c-c-class-wrappers-using-swig             
//
// Typemap for callbacks:
%define %cs_callback(TYPE, CSTYPE)
    %typemap(ctype) TYPE, TYPE& "void *"
    %typemap(in) TYPE  %{ $1 = ($1_type)$input; %}
    %typemap(in) TYPE& %{ $1 = ($1_type)&$input; %}
    %typemap(imtype, out="IntPtr") TYPE, TYPE& "CSTYPE"
    %typemap(cstype, out="IntPtr") TYPE, TYPE& "CSTYPE"
    %typemap(csin) TYPE, TYPE& "$csinput"
%enddef