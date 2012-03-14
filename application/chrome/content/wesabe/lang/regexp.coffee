exports.escape = RegExp.escape or (text) -> text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
