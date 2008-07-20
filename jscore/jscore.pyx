cdef extern from *:
    ctypedef int size_t
    ctypedef char * const_char_ptr "const char *"

cdef extern from "stdlib.h":
    cdef void *malloc(size_t size)
    cdef void free(void *data)

cdef extern from "string.h":
    cdef size_t strlen(const_char_ptr data)

cdef extern from "Python.h":
    cdef object PyUnicode_DecodeUTF8(const_char_ptr s, Py_ssize_t size,
            char *errors)
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
    cdef void JSGlobalContextRelease(JSGlobalContextRef ctx)

    ctypedef unsigned short JSChar
    cdef JSStringRef JSStringCreateWithUTF8CString(const_char_ptr string)
    cdef size_t JSStringGetLength(JSStringRef string)
    cdef bint JSStringIsEqual(JSStringRef a, JSStringRef b)
    cdef size_t JSStringGetUTF8CString(JSStringRef string, char *buffer,
            size_t bufferSize)
    cdef size_t JSStringGetMaximumUTF8CStringSize(JSStringRef string)
    cdef bint JSStringIsEqualToUTF8CString(JSStringRef a, const_char_ptr b)
    cdef void JSStringRelease(JSStringRef string)

    cdef bint JSCheckScriptSyntax(JSContextRef ctx, JSStringRef script,
            JSStringRef sourceURL, int startingLineNumber,
            JSValueRef *exception)
    cdef JSValueRef JSEvaluateScript(JSContextRef ctx, JSStringRef script,
            JSObjectRef thisObject, JSStringRef sourceURL,
            int startingLineNumber, JSValueRef *exception)
    cdef void JSGarbageCollect(JSContextRef ctx)

    cdef JSType JSValueGetType(JSContextRef ctx, JSValueRef value)
    cdef JSValueRef JSValueMakeBoolean(JSContextRef ctx, bint boolean)
    cdef bint JSValueToBoolean(JSContextRef ctx, JSValueRef value)
    cdef JSValueRef JSValueMakeNumber(JSContextRef ctx, double number)
    cdef double JSValueToNumber(JSContextRef ctx, JSValueRef value,
            JSValueRef *exception)
    cdef JSValueRef JSValueMakeString(JSContextRef ctx, JSStringRef string)
    cdef JSStringRef JSValueToStringCopy(JSContextRef ctx, JSValueRef value,
            JSValueRef *exception)
    cdef JSValueRef JSValueMakeNull(JSContextRef ctx)
    cdef JSValueRef JSValueMakeUndefined(JSContextRef ctx)
    cdef bint JSValueIsObject(JSContextRef ctx, JSValueRef value)
    cdef JSObjectRef JSValueToObject(JSContextRef ctx, JSValueRef value,
            JSValueRef *exception)

    cdef JSValueRef JSObjectGetProperty(JSContextRef ctx, JSObjectRef object_,
            JSStringRef propertyName, JSValueRef *exception)
    cdef JSValueRef JSObjectGetPropertyAtIndex(JSContextRef ctx,
            JSObjectRef object_, unsigned propertyIndex,
            JSValueRef *exception)


class JSException(Exception):
    exception_value = None

    def __init__(self, message, exception_value):
        Exception.__init__(self, message)
        self.exception_value = exception_value

class JSSyntaxError(JSException):
    error_line = None
    source_id = None
    source_url = None

    def __init__(self, message, exception_value, errLine, sourceId, sourceURL):
        JSException.__init__(self, message, exception_value)
        self.error_line = errLine
        self.source_id = sourceId
        self.source_url = sourceURL


cdef class Context
cdef class String
cdef _check_exception(Context ctx, JSValueRef exception, message):
    if not exception:
        return

    cdef JSValueRef innerexception = NULL
    cdef JSContextRef ctx_ = ctx.ctx

    cdef JSStringRef exceptionstring = NULL
    cdef String s

    value = _value_load(ctx, exception).python_value(ctx)
    if isinstance(value, JSObject):
        #TODO Parse and raise appropriate exceptions
        exceptionstring = JSValueToStringCopy(ctx_, exception, &innerexception)
        _check_exception(ctx, innerexception,
            'An exception occurred while parsing a prior exception')

        s = String(None)
        s.str_ = exceptionstring
        v = str(s)

        JSStringRelease(exceptionstring)

        raise JSException(v, v)
    else:
        raise JSException(message, value)


cdef class String:
    cdef JSStringRef str_

    def __init__(self, s):
        if s is None:
            self.str_ = NULL
            return

        if not isinstance(s, basestring):
            raise TypeError('Provided value should be a string')

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


cdef class JSObject
def _object_test_equality():
    cdef Context ctx1 = GlobalContext()
    cdef Context ctx2 = GlobalContext()

    cdef JSStringRef script = JSStringCreateWithUTF8CString('o = Object();')

    cdef JSValueRef o1_ = JSEvaluateScript(ctx1.ctx, script, NULL, NULL, 0,
            NULL)
    assert JSValueIsObject(ctx1.ctx, o1_), 'Generated value is not an object'
    cdef JSObjectRef obj1 = JSValueToObject(ctx1.ctx, o1_, NULL)

    cdef JSValueRef o2_ = JSEvaluateScript(ctx1.ctx, script, NULL, NULL, 0,
            NULL)
    assert JSValueIsObject(ctx1.ctx, o2_), 'Generated value is not an object'
    cdef JSObjectRef obj2 = JSValueToObject(ctx1.ctx, o2_, NULL)

    JSStringRelease(script)

    cdef JSObject o1 = JSObject(_NO_INIT)
    o1.obj = obj1
    o1.ctx = ctx1
    cdef JSObject o2 = JSObject(_NO_INIT)
    o2.obj = obj1
    o2.ctx = ctx1
    assert o1 == o2, 'Equality failed'

    o2.obj = obj2
    assert not o1 == o2, 'Non-equality based on obj failed'

    o2.obj = obj1
    o2.ctx = ctx2
    assert not o1 == o2, 'Non-equality based on ctx failed'


cdef class JSObject:
    cdef JSObjectRef obj
    cdef Context ctx

    def __richcmp__(JSObject self, JSObject b, op):
        if op == 2:
            return self.ctx.ctx == b.ctx.ctx and self.obj == b.obj

        raise NotImplementedError

    def __getattribute__(self, name):
        try:
            res = object.__getattribute__(self, name)
            return res
        except AttributeError:
            pass

        cdef String jsname = String(name)
        cdef JSValueRef exception = NULL
        cdef JSValueRef o = JSObjectGetProperty(self.ctx.ctx, self.obj,
                jsname.str_, &exception)
        _check_exception(self.ctx, exception,
                'Error while getting attribute%s' % name)
        value = _value_load(self.ctx, o).python_value(self.ctx)
        if value is UNDEFINED:
            raise AttributeError('No attribute %s defined' % name)
        return value

    def _get_slice(self, s):
        if s.stop is None:
            raise ValueError('Slice stop index is mandatory')

        if s.step and s.step < 1:
            raise ValueError('Slice step should be >= 1')

        l = list()
        cdef JSValueRef o
        cdef JSValueRef exception = NULL

        for i in xrange(s.start or 0, s.stop, s.step or 1):
            o = JSObjectGetPropertyAtIndex(self.ctx.ctx, self.obj, i,
                    &exception)
            _check_exception(self.ctx, exception,
                    'Error while getting property at index %d' % i)
            value = _value_load(self.ctx, o).python_value(self.ctx)
            l.append(value)

        return tuple(l)

    def __getitem__(self, item):
        if not isinstance(item, (int, long, slice)):
            raise TypeError('Only numeric items are accessible')

        if isinstance(item, slice):
            return self._get_slice(item)

        if item < 0:
            raise IndexError('Negative indices are not supported')

        cdef JSValueRef exception = NULL
        cdef int idx = item
        cdef JSValueRef o = JSObjectGetPropertyAtIndex(self.ctx.ctx,
                self.obj, idx, &exception)
        _check_exception(self.ctx, exception,
                'Error while getting property at index %d' % item)

        value = _value_load(self.ctx, o).python_value(self.ctx)
        if value is UNDEFINED:
            raise IndexError('Invalid index %d' % item)
        return value


cdef class Context:
    cdef JSContextRef ctx

    def get_global_object(self):
        cdef JSObjectRef real_obj = JSContextGetGlobalObject(self.ctx)
        cdef JSObject obj = JSObject()
        obj.obj = real_obj
        obj.ctx = self
        return obj

    def check_script_syntax(self, script, sourceURL=None,
            startingLineNumber=0):
        if not script:
            raise ValueError('No script provided')
        cdef String jsscript = String(script)
        cdef String jssource = String(sourceURL)

        cdef JSValueRef exception = NULL

        ret = JSCheckScriptSyntax(self.ctx, jsscript.str_, jssource.str_,
                startingLineNumber, &exception)

        _check_exception(self, exception,
            'Exception while validating script syntax')

        return ret

    def garbage_collect(self):
        JSGarbageCollect(self.ctx)

    #TODO Fix args: thisObject
    def evaluate_script(self, script, sourceURL=None, startingLineNumber=0):
        if not script:
            raise ValueError('No script provided')

        cdef String jsscript = String(script)
        cdef String jssource = String(sourceURL)
        cdef JSValueRef exception = NULL

        cdef JSValueRef result = JSEvaluateScript(self.ctx, jsscript.str_,
                NULL, jssource.str_, startingLineNumber, &exception)
        _check_exception(self, exception, 'Exception while evaluating script')

        pythonresult = _value_load(self, result)

        return pythonresult.python_value(self)

cdef class GlobalContext(Context):
    #TODO Fix arguments
    def __init__(self):
        self.ctx = JSGlobalContextCreate(NULL)

    def __dealloc__(self):
        cdef JSGlobalContextRef ctx = <JSGlobalContextRef>self.ctx
        JSGlobalContextRelease(ctx)
        JSGarbageCollect(self.ctx)


class UndefinedType: pass
UNDEFINED = UndefinedType()

cdef class _Value
cdef _value_load(Context ctx, JSValueRef value):
    mapping = {
            kJSTypeBoolean: BooleanValue,
            kJSTypeNumber: NumberValue,
            kJSTypeString: StringValue,
            kJSTypeNull: NullValue,
            kJSTypeUndefined: UndefinedValue,
            kJSTypeObject: ObjectValue,
    }

    cdef JSType t = JSValueGetType(ctx.ctx, value)

    if not t in mapping:
        raise ValueError('Unknown JSValueRef type provided')

    tcls = mapping[t]

    cdef _Value inst = tcls(None, _NO_INIT)
    inst.value = value

    return inst

cdef _value_test_generic(Context ctx, JSValueRef value, content, valuetype,
        pythontype):
    o = _value_load(ctx, value)
    assert(isinstance(o, valuetype))
    o = o.python_value(ctx)
    assert(isinstance(o, pythontype))
    assert(o == content)

def _value_test_bool():
    cdef Context ctx = GlobalContext()
    cdef JSValueRef v = JSValueMakeBoolean(ctx.ctx, True)
    _value_test_generic(ctx, v, True, BooleanValue, bool)

def _value_test_number():
    cdef Context ctx = GlobalContext()
    cdef JSValueRef v = JSValueMakeNumber(ctx.ctx, 123.456)
    _value_test_generic(ctx, v, 123.456, NumberValue, float)

def _value_test_string():
    cdef Context ctx = GlobalContext()
    cdef JSStringRef s = JSStringCreateWithUTF8CString(u'abc123')
    cdef JSValueRef v = JSValueMakeString(ctx.ctx, s)
    _value_test_generic(ctx, v, u'abc123', StringValue, unicode)

def _value_test_null():
    cdef Context ctx = GlobalContext()
    cdef JSValueRef v = JSValueMakeNull(ctx.ctx)
    from types import NoneType
    _value_test_generic(ctx, v, None, NullValue, NoneType)

def _value_test_undefined():
    cdef Context ctx = GlobalContext()
    cdef JSValueRef v = JSValueMakeUndefined(ctx.ctx)
    _value_test_generic(ctx, v, UNDEFINED, UndefinedValue, UndefinedType)

def _value_test_object():
    cdef Context ctx = GlobalContext()
    cdef JSStringRef script = JSStringCreateWithUTF8CString('o = Object();')
    cdef JSValueRef o = JSEvaluateScript(ctx.ctx, script, NULL, NULL, 0, NULL)
    JSStringRelease(script)
    cdef JSObject expected = JSObject()
    expected.obj = JSValueToObject(ctx.ctx, o, NULL)
    expected.ctx = ctx
    _value_test_generic(ctx, o, expected, ObjectValue, JSObject)

class _Dummy: pass
_NO_INIT = _Dummy()

cdef class _Value:
    cdef JSValueRef value

    def python_value(self, Context ctx):
        raise NotImplementedError


cdef class BooleanValue(_Value):
    def __init__(self, Context ctx, value):
        if value is _NO_INIT:
            return

        if not value in (True, False):
            raise ValueError('Value should be True or False')

        if not ctx:
            raise ValueError('Context ctx not provided')

        self.value = JSValueMakeBoolean(ctx.ctx, value)

    def python_value(self, Context ctx):
        if not ctx:
            raise ValueError('Context ctx not provided')
        return JSValueToBoolean(ctx.ctx, self.value)


cdef class NumberValue(_Value):
    def __init__(self, Context ctx, value):
        if value is _NO_INIT:
            return

        value = float(value)

        if not ctx:
            raise ValueError('Context ctx not provided')

        self.value = JSValueMakeNumber(ctx.ctx, value)

    def python_value(self, Context ctx):
        if not ctx:
            raise ValueError('Context ctx not provided')
        cdef JSValueRef exception = NULL
        ret = JSValueToNumber(ctx.ctx, self.value, &exception)
        _check_exception(ctx, exception, 'Error while parsing number value')
        return ret


cdef class StringValue(_Value):
    def __init__(self, Context ctx, value):
        if value is _NO_INIT:
            return

        cdef String svalue
        if not isinstance(value, String):
            svalue = String(value)
        else:
            svalue = value

        if not ctx:
            raise ValueError('Context ctx not provided')

        self.value = JSValueMakeString(ctx.ctx, svalue.str_)

    def python_value(self, Context ctx):
        if not ctx:
            raise ValueError('Context ctx not provided')
        cdef JSValueRef exception = NULL
        cdef JSStringRef s = JSValueToStringCopy(ctx.ctx, self.value,
                &exception)
        _check_exception(ctx, exception, 'Error building string value')
        cdef String so = String(None)
        so.str_ = s
        return unicode(so)


cdef class NullValue(_Value):
    def __init__(self, Context ctx, value):
        if value is _NO_INIT:
            return

        if value is not None:
            raise TypeError('NullValue can only be initialized with None as value')
        if not ctx:
            raise ValueError('Context ctx not provided')

        self.value = JSValueMakeNull(ctx.ctx)

    def python_value(self, Context ctx):
        return None


cdef class UndefinedValue(_Value):
    def __init__(self, Context ctx, value):
        if value is _NO_INIT:
            return

        if value is not UNDEFINED:
            raise TypeError('UndefinedValue can only be initialized with UNDEFINED as value')

        if not ctx:
            raise ValueError('Context ctx not provided')

        self.value = JSValueMakeUndefined(ctx.ctx)

    def python_value(self, Context ctx):
        return UNDEFINED


cdef class ObjectValue(_Value):
    def __init__(self, Context ctx, value):
        if value is _NO_INIT:
            return

        if not ctx:
            raise ValueError('Context ctx not provided')

        raise RuntimeError('Creating ObjectValues is not possible, abort')

    def python_value(self, Context ctx):
        if not ctx:
            raise ValueError('Context ctx not provided')
        cdef JSValueRef exception = NULL
        cdef JSObjectRef o = JSValueToObject(ctx.ctx, self.value, &exception)
        _check_exception(ctx, exception, 'Error fetching object from value')
        cdef JSObject o_ = JSObject()
        o_.obj = o
        o_.ctx = ctx
        return o_
