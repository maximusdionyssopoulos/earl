package cf_extensions

foreign import CoreFoundation "system:CoreFoundation.framework"
import cf "core:sys/darwin/CoreFoundation"

Number :: cf.TypeRef
NumberType :: enum i64 {
	SInt8Type     = 1,
	SInt16Type    = 2,
	SInt32Type    = 3,
	SInt64Type    = 4,
	Float32Type   = 5,
	Float64Type   = 6,
	CharType      = 7,
	ShortType     = 8,
	IntType       = 9,
	LongType      = 10,
	LongLongType  = 11,
	FloatType     = 12,
	DoubleType    = 13,
	CFIndexType   = 14,
	NSIntegerType = 15,
	CGFloatType   = 16,
}

@(private)
@(link_prefix = "CF", default_calling_convention = "c")
foreign CoreFoundation {
	NumberGetValue :: proc(number: Number, theType: NumberType, value: rawptr) -> bool ---
}

cf_number_get_value :: proc(number: Number, $T: typeid, value: ^T) -> bool {
	type_enum: NumberType

	switch typeid_of(T) {
	case typeid_of(i8):
		type_enum = .SInt8Type
	case typeid_of(i16):
		type_enum = .SInt16Type
	case typeid_of(i32):
		type_enum = .SInt32Type
	case typeid_of(i64):
		type_enum = .SInt64Type
	case typeid_of(f32):
		type_enum = .Float32Type
	case typeid_of(f64):
		type_enum = .Float64Type
	}

	return NumberGetValue(number, type_enum, rawptr(value))
}
