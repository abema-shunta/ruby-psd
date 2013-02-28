require '../lib/ruby_psd.rb'

psd = RubyPSD.new("./sample.psd")
#Generate New Document

`rm -f ./sample.psd`

psd.width = 640
psd.height = 960
psd.layers = [
  "[img] background",
  [
    "[img] title",
    [
      "[btn] edit_button",
      [ 
        "content" 
      ],
      "content" 
    ],
    "[img] pin_animation_background",
    [
      "[img] pin_animation",
      [
        "[f] frame1",
        ["content"],
        "[f] frame2",
        ["content"],
        "[f] frame3",
        ["content"],
        "[f] frame4",
        ["content"]
      ],
      "content",    
    ],
    "[img] animation_label",
    ["content"],
    "[img] list_label",
    ["content"],
    "[img] checkbox_label",
    ["content"],
    "[img] list_background",
    ["content"],
    "[pg] progress",
    [
      "[knob] knob",
      ["content"],
      "filled",
      "empty"
    ],
    "[img] progress_bar_label",
    ["content"]
  ]
]

psd.generate
