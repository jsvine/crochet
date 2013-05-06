module Crochet
	VERSION = "0.0.1"
	class Hook
		# Map symbols to their class- or instance-relevant methods
		TYPE_SPECS = {
			:instance => {
				:accessor => :instance_method,
				:definer => :define_method,
				:evaluator => :instance_exec
			},
			:class => {
				:accessor => :method,
				:definer => :define_singleton_method,
				:evaluator => :class_exec
			}
		}
		def initialize(klass, &block)
			@klass = klass
			@methods = []
			self.instance_eval(&block) if block
		end
		def _attach(timing, destructive, method, method_type=:instance, &block)
			specs = TYPE_SPECS[method_type]

			# Capture the original method
			orig_method = @klass.method(specs[:accessor]).(method)

			# Redefine the method
			@klass.send(specs[:definer], method) do |*args|
				# Pass the original arguments "before" hook methods
				if timing == :before
					hook_result = self.send(specs[:evaluator], *args, &block)
					args = hook_result if destructive
				end

				# Call the original method and assign the result
				method_result = (method_type == :instance ? orig_method.bind(self) : orig_method).call(*args)

				# Pass method result, followed by the args it received, to "after" hook methods
				if timing == :after
					hook_result = self.send(specs[:evaluator], method_result, *args, &block)
					method_result = hook_result if destructive
				end

				# Finally, return the (optionally overridden) method result
				method_result
			end
			@methods << { :orig => orig_method, :name => method, :type => method_type }
			nil
		end

		# Define hook methods and their destructive twins
		[ :before, :after, :before!, :after! ].each do |method|
			define_method method do |*args, &block|
				str = method.to_s
				destructive = (str[-1] == "!")
				timing = (destructive ? str[0...-1].to_sym : method)
				_attach(timing, destructive, *args, &block)
			end
		end
		
		# When `destroy` is called, it should restore all affected methods
		def destroy
			@methods.each do |method|
				specs = TYPE_SPECS[method[:type]]
				@klass.send(specs[:definer], method[:name]) do |*args|
					(method[:type] == :instance ? method[:orig].bind(self) : method[:orig]).call(*args)
				end
			end
			@methods = []
		end
	end
end
