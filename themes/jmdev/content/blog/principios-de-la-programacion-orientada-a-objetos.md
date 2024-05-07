+++
title = "Principios de la programación orientada a objetos"
date = 2024-05-07
draft = false
tags = ['programacion', 'poo',]
description = "Descripción de los principios de la programación orientada a objetos."
+++

Del artículo en la Wikipedia:

> La programación orientada a objetos (POO) es un paradigma de programación que parte del concepto de "objetos" como base, los cuales contienen información en forma de campos (a veces también referidos como atributos cualidades o propiedades) y código en forma de métodos.
{class="blockquote"}

La programación orientada a objetos se basa en varios principios que ayudan a diseñar sistemas más eficientes y mantenibles.
A continuación, algunos de los principios fundamentales de la POO:

# Clases:
Una clase es una especie de "plantilla" en la que se definen los atributos y métodos predeterminados de un tipo de objeto. 
Esta plantilla se crea para poder crear objetos fácilmente. 
A la acción de crear nuevos objetos mediante la lectura y recuperación de los atributos y métodos de una clase se le conoce como instanciacion.

Un ejemplo de una clase sería algo como:


Lenguaje: **Ruby**
```ruby {linenos=table,anchorlinenos=true}
class User
  # name y age son los atributos de la clase User
  attr_accessor :name, :age

  # initialize es un metodo de la clase User.
  # Cabe destacar que en Ruby *initialize* es un metodo constructor, con el que se crean objetos de la clase (instanciacion).
  def initialize(name, age)
    @name = name
    @age = age
  end

  # sayhello es otro metodo de la clase User.
  def sayhello
    puts "Hola, mi nombre es #{name}"
  end
end
```

# Objetos:
Los objetos son instancias de clases. Cada objeto tiene su propio estado (datos) y comportamiento (métodos). La POO se centra en modelar el mundo real mediante la creación y manipulación de objetos.

Teniendo en cuenta la clase anterior, crear un objeto a partir de ella sería algo como:

Interprete Ruby: **Irb**
```sh {linenos=table,anchorlinenos=true}
irb(main):01> fulano = User.new("fulano", 20)
=> #<User:0x00007f307571fe38 @age=20, @name="fulano">
irb(main):02> fulano.name
=> "fulano"
irb(main):03> fulano.age
=> 20
irb(main):04> fulano.sayhello
Hola, mi nombre es fulano
=> nil
```

En este ejemplo, `fulano` sería el objeto que hemos instanciado (usando el método `new`) a partir de la clase `User`. Una vez creado el objeto, podemos acceder a  sus atributos `name`, `age`
y método `sayhello`.

# Encapsulación:
La encapsulación implica ocultar los detalles internos de una clase y exponer solo una interfaz pública.
Esto permite controlar el acceso a los datos y protegerlos de modificaciones no autorizadas.

En el ejemplo de arriba, se requiere la edad (`age`) al momento de instanciar el objeto, pero sí en lugar de solicitar la edad, tan solo solicitamos el año
de nacimiento, podríamos calcular la edad. Además este proceso de cálculo, no necesitaría ser accesible al público, ya que no sería necesario.

Lenguaje: **Ruby**
```ruby {linenos=table,anchorlinenos=true}
class User
  # name y yob son los atributos de la clase User
  attr_accessor :name, :yob

  # initialize es un metodo de la clase User.
  # Cabe destacar que en Ruby *initialize* es un metodo constructor, con el que se crean objetos de la clase (instanciacion).
  def initialize(name, yob)
    @name = name
    @yob = yob
    @age = nil
  end

  # sayhello es otro metodo de la clase User.
  def sayhello
    puts "Hola, mi nombre es #{name}"
  end

  def say_age
    age_calc
    puts "tengo #{@age} años"
  end


  private
  def age_calc
    @age = Time.now.year - @yob
  end
end
```

Ahora creamos de nuevo el objeto con la clase recién modificada:

Interprete Ruby: **Irb**
```sh {linenos=table,anchorlinenos=true}
irb(main):01> fulano = User.new("fulano", 2000)
=> #<User:0x00007fe0eb64a720 @age=nil, @name="fulano", @yob=2000>
irb(main):02> fulano.say_age
tengo 24 años
=> nil
irb(main):03> fulano.age_calc
(irb):31:in `<main>': private method `age_calc' called for an instance of User (NoMethodError)
```

Nótese que en el ejemplo, marcamos al método `age_calc` como privado, esto hace que dicho método no pueda ser llamado desde el objeto; sin embargo,
si podemos llamarlo desde la misma clase. Lo cual es lo que hacemos en el método `say_hello` para realizar el cálculo de edad antes de mostrarla.

Cabe destacar que al atributo `age` ahora no puede ser accedido desde el objeto, esto debido a que lo eliminamos del método `attr_accessor`, el cual es un método 
especial en ruby que genera los métodos `getter` (para leer/acceder al atributo desde el objeto) y `setter` (para modificar el atributo desde el objeto) automáticamente.

Hacer esta modificación en `age` también ayuda a conseguir la característica de encapsulación, ya que nos obliga a manipular a dicha propiedad a través de 
la misma clase y evitando así las modificaciones o manipulaciones no autorizadas.

En ruby, los métodos que no están debajo de una declaración `private` o `protected` son de acceso público, como por ejemplo el método `sayhello` y `say_age`

# Herencia:
La herencia permite crear nuevas clases basadas en clases existentes. Una clase derivada (subclase) hereda propiedades y métodos de su clase base (superclase). Esto fomenta la reutilización de código y la jerarquía de clases.

Digamos que queremos crear otra clase, por ejemplo `Seller`, pero esta debe tener las mismas características de la clase `User`, lo primero que pensaríamos sería
en copiar tal cual los mismos atributos y métodos en la nueva clase. Pero esto haría que nuestro código se repita en múltiples lugares. Para solventar esto
podemos usar la Herencia. Creamos una clase `Person` que contenga el código común entre las clases `User` y `Seller` y hacemos que dichas clases simplemente
hereden esas características.

Un ejemplo de herencia podría ser:

Lenguaje: **Ruby**
```ruby {linenos=table,anchorlinenos=true}
class Person
  # name y age son los atributos de la clase Person
  attr_accessor :name, :age

  # initialize es un metodo de la clase Person.
  # Cabe destacar que en Ruby *initialize* es un metodo constructor, con el que se crean objetos de la clase (instanciacion).
  def initialize(name, age)
    @name = name
    @age = age
  end

  # sayhello es otro metodo de la clase Person.
  def sayhello
    puts "Hola, mi nombre es #{name} y soy #{self.class}"
  end
end

# La clase User hereda caracteristicas de la clase Person
class User < Person
end

# La Seller User hereda caracteristicas de la clase Person
class Seller < Person
end
```

Ahora instanciamos algunos objetos y comprobamos:

Interprete Ruby: **Irb**
```sh {linenos=table,anchorlinenos=true}
irb(main):01> fulano = User.new("fulano", 20)
=> #<User:0x00007f4637f86798 @age=20, @name="fulano">
irb(main):02> fulano.sayhello
Hola, mi nombre es fulano y soy User
=> nil
irb(main):03> mengano = Seller.new("mengano", 25)
=> #<Seller:0x00007f46379e6748 @age=25, @name="mengano">
irb(main):04> mengano.sayhello
Hola, mi nombre es mengano y soy Seller
```

Nótese como las clases `User` y `Seller` están totalmente vacías, sin embargo, sus objetos tienen atributos y métodos funcionales. Esta es la herencia en acción,
todos los atributos y métodos en dichas clases están siendo heredados de la clase `Person`. Se podrían agregar nuevos atributos y métodos más específicos 
a la clase `User` y `Seller` y aun así, seguir heredando métodos y atributos comunes desde la clase `Person` para evitar así código repetido.

# Abstracción:
La abstracción es la capacidad de representar conceptos complejos mediante modelos simplificados.
En POO, esto se logra mediante la creación de clases y objetos que encapsulan datos y comportamientos relacionados.

En el ejemplo de encapsulación, de hecho, podemos ver también un ejemplo de abstracción al usar el método `say_age`. Al llamar este método se debe primero
calcular la edad y almacenarla en el atributo `@age`; sin embargo, como usuario al utilizar `fulano.say_age` ni nos enteramos de este cálculo. Ni siquiera
nos enteramos de que hay un atributo adicional `@age` en donde se almacena el valor del cálculo. Esto de hecho como usuario no necesitamos saberlo en primera
instancia y es por eso que en el código se abstrae ese comportamiento.

De hecho, podríamos ir más allá y agregar comportamientos adicionales en este método `say_age` y su uso no se vería afectado.

Lenguaje: **Ruby**
```ruby {linenos=table,anchorlinenos=true}
class User
  # name y yob son los atributos de la clase User
  attr_accessor :name, :yob

  # initialize es un metodo de la clase User.
  # Cabe destacar que en Ruby *initialize* es un metodo constructor, con el que se crean objetos de la clase (instanciacion).
  def initialize(name, yob)
    @name = name
    @yob = yob
    @age = nil
  end

  # say_age es otro metodo de la clase User.
  def say_age
    age_calc
    sayhello
    puts "tengo #{@age} años"
  end

  private
  def age_calc
    @age = Time.now.year - @yob
  end

  # sayhello es otro metodo de la clase User.
  # ahora tambien es privado
  def sayhello
    puts "Hola, mi nombre es #{name}"
  end
end
```

Acá hemos movido el método `sayhello` debajo de la declaración `private` para que sea ahora de acceso privado, eso solo deja como método público
al método `say_age`, es lo único que el usuario necesitaría saber, el usuario no necesita saber del atributo `age` ni de los otros métodos en la clase.

Interprete Ruby: **Irb**
```ruby {linenos=table,anchorlinenos=true}
irb(main):01> fulano = User.new("fulano", 1980)
=> #<User:0x00007fbe14d06e00 @age=nil, @name="fulano", @yob=1980>
irb(main):02> fulano.say_age
Hola, mi nombre es fulano
tengo 44 años
=> nil
```

Incluso con el cambio, podemos seguir usando el método `say_age` sin problemas, el comportamiento obtenido es prácticamente el mismo.

# Polimorfismo:
El polimorfismo permite que objetos de diferentes clases respondan de manera similar a un mismo conjunto de métodos o mensajes.
Esto significa que un objeto puede tomar diferentes formas o comportarse de diferentes maneras según el contexto.
Por ejemplo, un método “calcularArea()” puede funcionar de manera diferente para diferentes formas geométricas (círculo, cuadrado, triángulo).
Esto se logra mediante la implementación de interfaces o la sobrescritura de métodos.

Un ejemplo de polimorfismo podría ser:

Lenguaje: **Ruby**
```ruby {linenos=table,anchorlinenos=true}
# creacion de la clase base
class Avion
  def motor
    puts "motor comun"
  end
end

# Clase JetPasajeros hereda de la clase Avion
class JetPasajeros < Avion
  # pero sobrescribimos el comportamiento del metodo motor heredado
  # para adaptarlo a las necesidades de la clase JetPasajeros
  def motor
    puts "motor Jet"
  end
end

# Clase Avioneta hereda de la clase Avion
class Avioneta < Avion
  # pero sobrescribimos el comportamiento del metodo motor heredado
  # para adaptarlo a las necesidades de la clase Avioneta
  def motor
    puts "motor de helices"
  end
end
```

Ahora creamos algunos objetos:

Interprete Ruby: **Irb**
```sh {linenos=table,anchorlinenos=true}
irb(main):01> avioncomun = Avion.new
=> #<Avion:0x00007fc18e746128>
irb(main):02> a380 = JetPasajeros.new
=> #<JetPasajeros:0x00007fc18e5e7610>
irb(main):03> avionetica = Avioneta.new
=> #<Avioneta:0x00007fc18e84e7c8>
irb(main):04> avioncomun.motor
motor comun
=> nil
irb(main):05> a380.motor
motor Jet
=> nil
irb(main):06> avionetica.motor
motor de helices
=> nil
```

Nótese que a pesar de que en las clases `JetPasajeros` y `Avioneta` estamos heredando métodos de la clase `Avion`, al usar el método `motor` heredado en los objetos,
correspondientes, el comportamiento es distinto en cada uno. Esto debido a que estamos sobreescribiendo el comportamiento de este método `motor` al heredarse.

Este es el polimorfismo en acción, en este caso usado en una herencia para la sobrescritura de métodos. Acá las clases hijas pueden comportarse como la
clase padre ya que está heredando sus características y comportamiento; sin embargo, eso no las ata a que no puedan también modificar alguno de los comportamientos
heredados.

Otro ejemplo de polimorfismo sería:

Lenguaje: **Ruby**
```ruby {linenos=table,anchorlinenos=true}
class GasStation

  def type(client)
    client.type
  end

  def price(client)
    client.price
  end
end

class Cheap
  def type
    puts "La gasolina elejida es de 85 octanos."
  end

  def price
    puts "El precio es de 0.5 el litro."
  end
end

class Expensive
  def type
    puts "La gasolina elejida es de 95 octanos."
  end

  def price
    puts "El precio es de 1.5 el litro."
  end
end
```

Ahora creamos algunos objetos y probamos:

Interprete Ruby: **Irb**
```sh {linenos=table,anchorlinenos=true}
irb(main):01> porlamar = GasStation.new
=> #<GasStation:0x00007f8783f56bf0>
irb(main):02> la_baratonga = Cheap.new
=> #<Cheap:0x00007f8783ec0060>
irb(main):03> carito_vale = Expensive.new
=> #<Expensive:0x00007f8783ef24e8>
irb(main):04> porlamar.type(la_baratonga)
La gasolina elejida es de 85 octanos.
=> nil
irb(main):05> porlamar.price(la_baratonga)
El precio es de 0.5 el litro.
=> nil
irb(main):06> porlamar.type(carito_vale)
La gasolina elejida es de 95 octanos.
=> nil
irb(main):07> porlamar.price(carito_vale)
El precio es de 1.5 el litro.
=> nil
```

Nótese como el objeto `porlamar` correspondiente a la clase `GasStation` puede ejecutar métodos de la clase `Cheap` así como
también métodos de la clase `Expensive`. Eso es polimorfismo en acción, dado que podemos trabajar con las capacidades de un objeto 
sin importar su tipo específico. 

Acá podría agregar más clases que hagan referencias a tipos de gasolina y sus costos,
mientras las nuevas clases contengan métodos públicos `type` y `price`, los objetos de la clase `GasStation` podrán trabajar con
esos nuevos objetos sin problemas.
