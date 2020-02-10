require 'kramdown/converter'

module Kramdown
    module Converter
        module MathEngine
            module SimpleMath
                def self.call(converter, el, opts)
                    display_mode=el.options[:category]
                    answer="formula generated from "
                    answer<<el.value
                    if display_mode == :block
                        answer<<" [block mode]\n"
                    end
                    answer
                end
            end
        end
        add_math_engine(:simplemath, MathEngine::SimpleMath)
    end
end
