cdef extern from "JavaScriptCore/JavaScript.h":
        ctypedef JSValueRef
        ctypedef JSObjectRef
        ctypedef JSContextRef
        ctypedef JSGlobalContextRef
        ctypedef JSStringRef
        ctypedef JSClassRef

cdef class Value:
        cdef JSValueRef _obj

cdef class Object:
        cdef JSObjectRef _obj

cdef class String:
        cdef JSStringRef _obj

cdef class Class:
        cdef JSClassRef _obj

cdef class Context:
        cdef JSContextRef _obj

cdef class GlobalContext(Context):
        cdef JSGlobalContextRef _obj

        def __new__(self, Class globalObjectClass=None):
                print globalObjectClass
                if globalObjectClass:
                        cls = globalObjectClass._obj
                else:
                        cls = None
                print cls
                self._obj = JSGlobalContextCreate(cls)
                print self._obj

cdef extern from "JavaScriptCore/JSContextRef.h":
        JSGlobalContextRef JSGlobalContextCreate(JSClassRef globalObjectClass)
