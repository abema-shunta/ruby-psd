ruby-psd
========

Library for generating psd skeleton file simple and by scripting of Ruby. 

Overview
--------

Sometimes sharing a specification of application is difficult. 
Even director or planner made a based specification on document,
designer feels stress sometimes to check specification again and again. 

This library is made for generate skeletons consisted by layer groups in psd files easy.
With using ruby code, you can make folder / file structures by coding. 

Install
----------

    gem install ruby-psd


Usage
---------

    require 'ruby-psd'
    
    # Generate New Document
    psd = RubyPSD.new("./path/to/you/want/generate/sample.psd")
    
    # Set psd document's canvas size. default is 0 each. 
    psd.width = 640
    psd.height = 960
   
    # Define layer group structure you want to generate
    psd.layers =
    [
      "title",
      [
      	"button",
      	"inner_group",
      	[
      	  "more_inner"
      	]
      ]
    ]
    
    # Generate psd 
    psd.generate
    
    # If you want to change path, reset the path string
    psd.path = ("./another/path/sample.psd")


