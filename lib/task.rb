require 'time'

class Task
    
    OPTIONS_DEFAULT = {
        flags: []
    }

    # retourne une tâche
    def self.ajouter params
        
        contenu = params.shift
        id = (@tableau_taches.map(&:id).max||-1) +1
        # on utilise l'opérateur ou qui dit que si on ne trouve pas max on renvoie -1
        
        if contenu.nil?
            raise TaskmanError, "add a besoin d'un parametre décrivant la tâche"
            # vu que c'est une erreur TaskmanError, il va renvoyer un message spéciale, comme défini dans le command.rb
            exit
        end
        
        hash = {}
        params.each do |params|
            k,v = params.split(':') 
            # je sépare en deux variable la clé et la valeur
            hash[k.to_sym] = v
            # je crée un nouvel élément dans hash avec la clé que je passe en symbol et je lui passe la valeur de la variable v
        end
        
        new_task = Task.new id, contenu, hash
        
        @tableau_taches << new_task
    end
    
    def self.clear
        @tableau_taches = []
    end
    
    def self.get_task id
        @tableau_taches.select{|tache| tache.id == id}.first
    end
    
    def self.supprimer id
        @tableau_taches.reject!{|tache| tache.id == id.to_i }
    end
    
    # Charge les tâche depuis un fichier JSON
    def self.load file
        if File.exists?(file)
            str = File.read(file)
            tableau = JSON.parse(str)
            
            @tableau_taches = tableau.map do |tache|
                opts = tache.reject{|k,v| ["id", "content", "is_done"].include?(k)}
                # Je rejette du tableau tout les éléments qui ont :id, is_done ou :content comme clé afin de ne garder que les options
                Task.new(tache["id"], tache["content"], opts, tache["is_done"] )
            end
        else
            @tableau_taches = []
        end
        
    end
    
    # Sauvegarde les taches vers un fichier JSON
    def self.save file
        File.open(file, "w") do |file|
            file.write(@tableau_taches.to_json)
            # les méthodes file.open, file.read, file.write, sont des méthodes qui vont servir a créer et modifier des fichiers.
        end
    end
    
    # afficher les tâches
    def self.display filtre={}
        puts "********TASKMAN********".bold.white
        puts "LISTE DES TACHES".bold.white

        # On peut écrire de cette façon lorsque l'on cherche à appeler la méthode d'un objet
        # Dans ce cas ci, pour chaque tâches de mon tableau_taches, j'utilise la méthode display pour les afficher
        @tableau_taches.reject do |t| # pour chaques tâches t
            x = filtre.map do |k,v|
                field_value = t.send(k)
                
                if field_value.is_a?(Array)
                    # si c'est un array (par exemple dans le cadre du flag qui peu avoir plusieurs éléments, exemple : "important" ou "urgent")
                    field_value.include?(v)
                else
                    !!(field_value.to_s =~ /^#{v}/)
                    # le not not ( !! ) permet de récupérer n'importe quelle variable en boolen
                    # si la valeur du champ commence par le contenu de la variable v
                    # le ^ veut dire que ca commence par
                    # /^#{v}/ est une regex
                end
            end
            # p x
            x.uniq.include?(false)
            # le .uniq renvoie une seul fois chaque élément d'un tableau, même si il est présent plusieurs fois
            # par exemple si dans un tableau il y a trois fois "bateau" il va le renvoyer qu'une fois parce que il ne renvoie qu'une fois la même valeur
        end.each(&:display)
    end

    attr_accessor :id, :content, :flags, :date
    attr_reader :is_done
    # On met is_done en reader seulement comme ça on ne peux le modifier une fois qu'il a été validé
    
    # la méthode sert a transformer le flags en un tableau si celui ci est une chaine de caractère, 
    # car j'utilise un join pour l'afficher en console, et le join ne fonctionne pas sur les strings
    def flags= x
        if x
            if x.is_a?(Array)
                @flags = x
            elsif x.is_a?(String)
                @flags = x.split(",")
            else
                raise "flags = #{x.class} impossible"
            end
        else
            @date = x
        end
    end
    
    def date= x
        if x
            if x.is_a?(Time)
                @date = x
            elsif x.is_a?(String)
                @date = Time.parse(x);
            else
                raise "date = #{x.class} impossible"
            end
        else
            @date = x
        end
    end
    
    
    def initialize id, content, opts={}, is_done = false
        opts = OPTIONS_DEFAULT.merge(opts)
        
        @id = id
        @content = content
        
        opts.each do |k,v|
            if respond_to?("#{k}=")
                # Si notre classe a la méthode "k" dans le opts
                send("#{k}=", v)
                # Alors la méthode "k" = la valeur qui est passée, on lui assigne dynamiquement
                # Mon #{k}= est une setter 
            else
                raise "Je ne connais pas ce champs : #{k}"
            end
        end
        
        # Je supprime l'assignement de flag étant donné que je le fais dynamiquement dans le each de opts ci dessus
        # @flags = opts[:flags]
        @is_done = is_done
    end
    
    # la methode to_json nous est donnée via la gem Json, il est nécessaire de passer l'argument opts={} même si on ne lui passe rien lorsque l'ont appel la méthode
    # on ne lui passe rien entre {} vu qu'il n'y a pas d'options par défaut
    def to_json opts={}
        {
            id: @id,
            content: @content,
            flags: @flags,
            date: @date,
            is_done: @is_done
        }.to_json(opts)
    end
    
    def display
        puts "[#{ @is_done ? "X".green : ".".red }] #{@id.to_s.light_blue} - #{@content.bold.white} - (#{@flags.join(",")}) -  #{ @date.try(:strftime, "%Y-%m-%d")}"
        # puts "[#{ @is_done ? "X".green : ".".red }] #{@id.to_s.light_blue} - #{@content.bold.white} - (#{@flags.join(",")}) -  #{ @date == nil ? "pas de date" : @date.strftime("%Y-%m-%d")}"
    end
    
    def done
        @is_done = true
    end
    
    @tableau_taches =  []
end
