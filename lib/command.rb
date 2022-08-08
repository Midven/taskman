module Command
    
    @commands = {}
    
    def self.display_help
        puts "taskman [commande] [contenu|id] [options...]"
        puts "--------------------------------------------"
    
        @commands.each do |k,action|
        puts action.to_s
        end
    end
    
    def self.launch!
        command = ARGV.shift
        
        is_executed = false
        @commands.each do |k,action|
            if k == command
                is_executed = true
                action.apply(ARGV)
            end
        end
        
        unless is_executed
            display_help
        end
    end

    
    def self.register action
        @commands[action.command] = action
    end
    
    class Action
        attr_accessor :command, :arguments, :description, :block
        
        def initialize command, arguments, description, &block 
            # le block passé derrière le constructeur sera traité commme une variable grâce au & et donc on va pouvoir le stocker
            @command = command
            @block = block
            @arguments = arguments
            @description = description
        end
        
        def apply arguments
            begin
                block.call(arguments)
            rescue TaskmanError => e
                puts "ERREUR : #{e.message.light_red}"
                # puts "Une erreur utilisateur!"
                # mettre la gestion des erreurs spécialisées en premier
            rescue => e
                puts "Une erreur ruby!"
            end
            # p e
        end
        
        def register!
            Command.register(self)
        end
        
        def to_s
            puts "#{@command} #{@arguments}\t *#{@description}"
        end
    end
  
    class TaskAction < Action
        def initialize command, arguments, description, &block
            super command, arguments, description, &block
            # Avec le super on appel le constructeur de la classe mère ( Action )
        end
        
        def apply arguments
            id = arguments.shift.to_i
            task = Task.get_task(id)
            
            if task.nil?
                puts "La tâche #{id} n'existe pas!"
                exit
            end
            
            begin
                block.call(task, arguments)
            rescue TaskmanError => e
                puts "ERREUR : #{e.message.light_red}"
                # puts "Une erreur utilisateur!"
                # mettre la gestion des erreurs spécialisées en premier
            rescue => e
                puts "Une erreur ruby!"
            end
            
        end
        
        def to_s
            puts "#{@command} :id #{@arguments}\t *#{@description}"
        end
    end
    
    
    
    def self.define &block
        CommandDSL.new(&block)
    end
    
    
    # Ma structure DSL qui va me permettre d'encoder une commande dans la console
    class CommandDSL
        
        def initialize &block
            instance_eval(&block)
            # la méthode instance_eval permet de lancer un block dans un contexte d'un objet, 
            # on va pouvoir accéder au mot clé self et du coup aux méthodes du DSL qu'on a créé
        end
        
        # l'argument passé pour la commande ( add ou del par exemple)
        def args str
            @args = str
        end
        
        # description de l'argument
        def desc str
            @desc = str
        end
        
        def action name, &block
            Command::Action.new(name.to_s, @args, @desc, &block).register! 
            # en fonction des éléments passé dans la console, il va se passer des choses différentes ( add ou del par exemple)
            @args = ""
            @desc = ""
            # Je réinitialise args et desc
        end
        
        def task_action name, &block
            Command::TaskAction.new(name.to_s, @args, @desc, &block).register!
            
            @args = ""
            @desc = ""
        end
    end
    
end