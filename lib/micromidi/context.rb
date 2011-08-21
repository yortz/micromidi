#!/usr/bin/env ruby
#

module MicroMIDI
  
  class Context
    
    include Instructions::Composite
    
    attr_reader :state
            
    def initialize(ins, outs, &block)
      
      @state = State.new(ins, outs)
      
      @instructions = {
        :effect => Instructions::Effect.new(@state),
        :input => Instructions::Input.new(@state),      
        :message => Instructions::Message.new(@state),
        :output => Instructions::Output.new(@state),
        :sticky => Instructions::Sticky.new(@state)
      }
       
      instance_eval(&block) unless block.nil?
    end
    
    def repeat
      self.send(@state.last_command[:method], *@state.last_command[:args]) unless @state.last_command.nil?
    end
    
    def method_missing(m, *a, &b)
      delegated = false
      outp = nil
      options = a.last.kind_of?(Hash) ? a.last : {}
      do_output = options[:output] || true
      [@instructions[:message], @instructions[:effect]].each do |dsl|
        if dsl.respond_to?(m)
          msg = dsl.send(m, *a, &b)
          outp = @state.auto_output && do_output ? @instructions[:output].output(msg) : msg
          delegated = true
        end
      end
      unless delegated
        [@instructions[:input], @instructions[:output], @instructions[:sticky]].each do |dsl| 
          if dsl.respond_to?(m)
            outp = dsl.send(m, *a, &b)
            delegated = true
          end
        end
      end
      @state.record(m, a, b, outp)
      delegated ? outp : super
    end
        
  end
end