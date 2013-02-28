require '../lib/main.rb'

psd = RubyPSD.new("./sample.psd")
#Generate New Document

`rm -f ./sample.psd`

psd.width = 640
psd.height = 960
psd.layers = [
  "group",
  [
    "group_inner",
    "group_inner",
    ["[bsed] array_incum", "anarcy"],
    "group_inner",
    "group_inner"
  ]
]

psd.generate
