rule '.h' => ['.idl'] do |t|
  sh "#{XULSDK}/bin/xpidl -m header -I#{XULSDK}/idl #{t.source}"
end

rule '.xpt' => ['.idl'] do |t|
  sh "#{XULSDK}/bin/xpidl -m typelib -I#{XULSDK}/idl #{t.source}"
end
