class Object
    
    # Je redéfinis la classe existante à Ruby : Object à laquelle j'ajoute la méthode try, c'est du monkey patching
    
    def try *args
        if nil?
            nil
        else
            send *args
        end
    end
    
end