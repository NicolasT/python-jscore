cdef extern from *:
    ctypedef int size_t
    ctypedef char * const_char_ptr "const char *"

cdef extern from "stdlib.h":
    cdef void *malloc(size_t size)
    cdef void free(void *data)

cdef extern from "string.h":
    cdef size_t strlen(const_char_ptr data)

cdef extern from "Python.h":
    cdef object PyUnicode_DecodeUTF8(const_char_ptr s, Py_ssize_t size, char* errors)
    cdef object PyUnicode_AsUTF8String(object o)
    cdef const_char_ptr PyString_AsString(object o)

cdef extern from "JavaScriptCore/JavaScript.h":
    cdef struct OpaqueJSValue:
        pass
    ctypedef OpaqueJSValue *JSValueRef

    #TODO Defines
    cdef struct OpaqueJSContext:
        pass
    ctypedef OpaqueJSContext *JSContextRef
    ctypedef OpaqueJSContext *JSGlobalContextRef

    #TODO Defines
    cdef struct OpaqueJSClass:
        pass
    ctypedef OpaqueJSClass *JSClassRef

    #TODO Defines
    cdef struct OpaqueJSObject:
        pass
    ctypedef OpaqueJSObject *JSObjectRef

    #TODO Defines
    cdef struct OpaqueJSString:
        pass
    ctypedef OpaqueJSString *JSStringRef

    ctypedef enum JSType:
        kJSTypeUndefined
        kJSTypeNull
        kJSTypeBoolean
        kJSTypeNumber
        kJSTypeString
        kJSTypeObject

    cdef JSGlobalContextRef JSGlobalContextCreate(JSClassRef globalObjectClass)
    cdef JSObjectRef JSContextGetGlobalObject(JSContextRef ctx)

    ctypedef unsigned short JSChar
    cdef JSStringRef JSStringCreateWithUTF8CString(const_char_ptr string)
    cdef size_t JSStringGetLength(JSStringRef string)
    cdef bint JSStringIsEqual(JSStringRef a, JSStringRef b)
    cdef size_t JSStringGetUTF8CString(JSStringRef string, char* buffer, size_t bufferSize)
    cdef size_t JSStringGetMaximumUTF8CStringSize(JSStringRef string)
    cdef bint JSStringIsEqualToUTF8CString(JSStringRef a, const_char_ptr b)

    cdef bint JSCheckScriptSyntax(JSContextRef ctx, JSStringRef script, JSStringRef sourceURL, int startingLineNumber, JSValueRef* exception)
    cdef void JSGarbageCollect(JSContextRef ctx)

cdef class String:
    cdef JSStringRef str_

    def __cinit__(self, s):
        if s is None:
            self.str_ = NULL
            return
        s = s.encode('UTF-8')
        cdef char *cs = s
        self.str_ = JSStringCreateWithUTF8CString(cs)

    def __len__(self):
        if self.str_ == NULL:
            return 0

        return JSStringGetLength(self.str_)

    def __str__(String self):
        if self.str_ == NULL:
            raise ValueError('Can\'t get string out of NULL')

        cdef char *bytes = self._get_bytes()
        out = str(bytes.decode('utf-8'))
        free(bytes)
        return out

    def __unicode__(String self):
        if self.str_ == NULL:
            raise ValueError('Can\'t get unicode out of NULL')

        cdef char *bytes = self._get_bytes()

        #This is some extremely tricky business, not sure whether it's
        #completely correct
        l = JSStringGetMaximumUTF8CStringSize(self.str_)
        j = strlen(bytes)
        k = min(l, j)

        out = PyUnicode_DecodeUTF8(bytes, k, 'strict')

        free(bytes)

        return out


    cdef char *_get_bytes(self):
        if self.str_ == NULL:
            raise ValueError('Can\'t get bytes out of NULL')

        l = JSStringGetMaximumUTF8CStringSize(self.str_)
        l += 1
        cdef char *buff = <char *>malloc(l * sizeof(char))

        JSStringGetUTF8CString(self.str_, buff, l)

        return buff

    def __richcmp__(String self, b, int op):
        cdef char *cb
        cdef JSStringRef b__
        cdef String b_
        cdef JSStringRef a = <JSStringRef>(self.str_)
        cdef const_char_ptr ccb

        if op == 2: # ==
            if isinstance(b, String):
                b_ = <String>b
                b__ = <JSStringRef>(b_.str_)
                return JSStringIsEqual(a, b__)
            elif isinstance(b, unicode):
                tmp = PyUnicode_AsUTF8String(b)
                ccb = PyString_AsString(tmp)
                return JSStringIsEqualToUTF8CString(a, ccb)
            elif isinstance(b, basestring):
                tmp = PyUnicode_AsUTF8String(unicode(b))
                ccb = PyString_AsString(tmp)
                return JSStringIsEqualToUTF8CString(a, ccb)

            else:
                raise TypeError('Compared object should be of type str, unicode or String')

        raise NotImplementedError('Only equality operation (2) is supported')

cdef class Object:
    cdef JSObjectRef obj

cdef class Context:
    cdef JSContextRef ctx

    def get_global_object(self):
        cdef JSObjectRef real_obj = JSContextGetGlobalObject(self.ctx)
        cdef Object obj = Object()
        obj.obj = real_obj
        return obj

    def check_script_syntax(self, script, sourceURL=None, startingLineNumber=0):
        if not script:
            raise ValueError('No script provided')
        cdef String jsscript = String(script)
        cdef String jssource = String(sourceURL)

        #TODO Handle errors
        return JSCheckScriptSyntax(self.ctx, jsscript.str_, jssource.str_,
                startingLineNumber, NULL)

    def garbage_collect(self):
        JSGarbageCollect(self.ctx)

cdef class GlobalContext(Context):
    #TODO Fix arguments
    def __init__(self):
        self.ctx = <JSContextRef>JSGlobalContextCreate(NULL)
