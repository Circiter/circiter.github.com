require 'kramdown/converter'

module Kramdown::Converter
    module MathEngine
        module SimpleMath
            VERSION='1.0.0'

            def call(converter, el, opts)
                display_mode=el.options[:category]
                answer="formula generated from "
                answer<<el.value
                if displya_mode == :block
                    answer<<" [block mode]\n"
                end
                answer
            end
        end
    end
    add_math_engine(:simplemath, MathEngine::SimpleMath)
end
