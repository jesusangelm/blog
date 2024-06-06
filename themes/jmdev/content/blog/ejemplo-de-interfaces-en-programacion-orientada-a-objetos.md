+++
title = "Ejemplo de interfaz en programación orientada a objetos"
date = 2024-06-06
draft = false
tags = ['programacion', 'poo', 'interfaz', 'protocolo']
description = "Conceptos y ejemplos básicos de interfaz o protocolo en programación orientada a objetos."
+++

En programación orientada a objetos, una interfaz (también llamada **protocolo**)
es un tipo de datos que actúa como abstracción de una clase.
Esta describe un conjunto de firmas de métodos, cuyas implementaciones pueden
ser proporcionadas por varias clases que, por lo demás, no están 
necesariamente relacionadas entre sí. Se dice que una clase que proporciona 
los métodos enumerados en un protocolo adopta el protocolo o implementa la interfaz.

# Ejemplo en Java

A pesar de que no programo en Java y no lo conozco mucho, este lenguaje es uno de los que, junto a C/C++, se recomiendan para aprender conceptos como este, debido a que son justamente lenguajes orientados a objetos que implementan Interfaz. Además de eso, se pueden encontrar muchos ejemplos y documentación que usan Java.

De acuerdo con lo definido arriba, una interfaz básica sería algo como esto:

Lenguaje: **Java**
```java {linenos=table,anchorlinenos=true}
public interface Geometria {
    Double area(); // firma del metodo area()
    Double perimetro(); // firma del metodo perimetro()
}
```

Acá definimos simplemente una interfaz llamada `Geometria` la cual especifica la
firma de dos métodos `area()` y `perimetro()` los cuales no reciben parámetros
pero ambos métodos devuelven valores `Double` o decimal. Bien, esta interfaz es 
nuestra descripción de requisitos que deben cumplir las clases que deseen implementarla.

A mí me gusta ver una interfaz, como simplemente esto, una descripción o firma de métodos
que deben cumplir las clases que quieran ser reconocidas como `Geometria` además de su propia clase o tipo.

Cabe destacar que las interfaces tan solo indican firmas de métodos, ellas no describen qué debe tener el interior
de un método requerido por la interfaz. A esta solo le importa el nombre del método, los parámetros que este recibe
y el tipo de datos que debe retornar en caso de retornar algún dato.

Veamos esto más en detalle:

Digamos que tenemos el siguiente método.


Lenguaje: **Java**
```java {linenos=table,anchorlinenos=true}
public static void medidas(Geometria geometry) {
    System.out.println("Area: " + geometry.area());
    System.out.println("Perimetro: " + geometry.perimetro());
}
```

Este método `medidas(Geometria geometry)` recibe un parámetro del tipo `Geometria` el cual usa para llamar
dos métodos pertenecientes a `Geometria`: los cuales son `area()` y `perimetro()` para mostrar en pantalla lo que sea que estos
Métodos devuelven. Básicamente, el método lo que hace es mostrar el área y perímetro de alguna figura geométrica.

Vamos a crear una figura geométrica de ejemplo para usarla en el método:


Lenguaje: **Java**
```java {linenos=table,anchorlinenos=true}
public class Circle {
    Double radio; // atributo

    // metodo constructor
    public Circle(Double radio) {
        this.radio = radio;
    }
}
```

Esta clase `Circle` es sencilla, tan solo tiene un atributo `radio` y un método constructor que recibe
un parámetro de tipo `Double` llamado `radio` el cual se asignará al atributo `radio` al momento de la sustanciación de un objeto.

Bien, si intentamos usar un objeto de esta clase en el método `medidas` encontraremos dos problemas:

* El primero es que el método solo permite un tipo de dato `Geometria`, y nuestro objeto es de la clase `Circle`, por lo que hay 
incompatibilidad de tipos de datos.

* El segundo problema es que el método `medidas` internamente llama a los métodos `area()` y `perimetro()` del objeto recibido,
pero los objetos de la clase `Circle` no tienen estos métodos dado que no se ha definido en la clase `Circle`.

¿Cómo resolvemos esto? Sencillo, hacemos que `Circle` implemente la interfaz `Geometria` descrita más arriba.


Lenguaje: **Java**
```java {linenos=table,anchorlinenos=true}
// indicamos que la clase Circle ahora implementa la interfaz Geometria
public class Circle implements Geometria {
    Double radio;

    public Circle(Double radio) {
        this.radio = radio;
    }

    // implementacion del metodo area() tal como lo exije la interfaz
    @Override
    public Double area() {
        return Math.PI * radio * radio;
    }

    // implementacion del metodo perimetro() tal como lo exije la interfaz
    @Override
    public Double perimetro() {
        return 2 * Math.PI * radio;
    }
}
```

He aquí la nueva clase `Circle` implementando la interfaz `Geometria`

Ahora los objetos de la clase `Circle` cumplen con lo necesario para ser 
usados en el método `medidas` dado que al implementar la interfaz `Geometria`, dichos objetos
son reconocidos también como del tipo `Geometria`. Al implementar los métodos `area()` y `perimetros`
requeridos por la interfaz `Geometria`, cumplimos también con las llamadas de esos métodos en el método `medidas`.

Veamos:

Lenguaje: **Java**
```java {linenos=table,anchorlinenos=true}
public class Main {
    public static void main(String[] args) {
        var circulo = new Circle(5.0);

        medidas(circulo);
    }

    public static void medidas(Geometria geometry) {
        System.out.println("Area: " + geometry.area());
        System.out.println("Perimetro: " + geometry.perimetro());
    }
}
```

Esto mostraría en pantalla algo como:


```sh
Area: 78.53981633974483
Perimetro: 31.41592653589793
```

En este ejemplo hemos usado el método `medidas` tan solo con la clase `Circle`, pero la ventaja de nos
da la interfaz es que podemos definir otras clases que al implementar dicha interfaz, permita que esa nueva clase
pueda ser usada en nuestro método `medidas`.

Veamos la siguiente clase `Rectangle`:


Lenguaje: **Java**
```java {linenos=table,anchorlinenos=true}
public class Rectangle implements  Geometria {
    Double width;
    Double height;

    public Rectangle(Double width, Double height) {
        this.width = width;
        this.height = height;
    }

    @Override
    public Double area() {
        return width * height;
    }

    @Override
    public Double perimetro() {
        return 2 * width + 2 * height;
    }
}
```

Actualizamos nuestra implementación en el método `main`:


Lenguaje: **Java**
```java {linenos=table,anchorlinenos=true}
public class Main {
    public static void main(String[] args) {
        var circulo = new Circle(5.0);
        var rectangulo = new Rectangle(5.5, 4.4);

        medidas(circulo);
        medidas(rectangulo)
    }

    public static void medidas(Geometria geometry) {
        System.out.println("Area: " + geometry.area());
        System.out.println("Perimetro: " + geometry.perimetro());
    }
}
```

Esto mostraría en pantalla algo como:


```sh
Area: 78.53981633974483
Perimetro: 31.41592653589793

Area: 24.200000000000003
Perimetro: 19.8
```

Como se puede observar, podemos usar el método `medidas()` con objetos de cualquier clase, siempre y cuando
estas clases implementen la interfaz `Geometria`. Lo mejor de todo es que no tenemos que modificar el método `medidas()`
para que sea usada con objetos de otras clases.

# Ejemplo en Go

Go no es precisamente un lenguaje de programación orientado a objetos, pero permite que los métodos sean 
definidos en tipos definidos por el usuario. Go tiene el tipo de datos `interface` que es compatible con
cualquier tipo de datos que soporta un conjunto dado de métodos.

Veamos el ejemplo anterior en Go:

Lenguaje: **Go**
```go {linenos=table,anchorlinenos=true}
package main

import (
	"fmt"
	"math"
)

// definimos la interfaz geometria
type geometria interface {
	area() float64 // firma del metodo area()
	perimetro() float64 // firma del metodo perimetro()
}

// Go no es orientado a objeto, lo mas cercano en Go a una 
// clase son las struct
type circle struct {
	radio float64 // atributo de la struct circle
}

type rectangle struct {
    width, height float64 // atributos de la struct rectangle
}

// en Go los metodos de una struct se definen de esta forma
// y fuera de la definicion de la struct
func (c circle) area() float64 {
	return math.Pi * c.radio * c.radio
}

func (c circle) perimetro() float64 {
    // ejemplo de uso del atributo 'radio' de una struct dentro del metodo de dicha struct
	return 2 * math.Pi * c.radio
}

// En Go no existe keywords para indicar la implementacion de una interfaz
// en su lugar basta con cumplir con la firma de metodos de dicha interfaz.
func (r rectangle) area() float64 {  // aca cumplimos la firma del metodo area()
    return r.width * r.height
}

func (r rectangle) perimetro() float64 { // aca cumplimos con la firma del metodo perimetro()
    return 2*r.width + 2*r.height
}

// definicion de nuestra funcion medidas
// que recibe un parametro del tipo geometria
func medidas(g geometria) {
	fmt.Println(g.area())
	fmt.Println(g.perimetro())
}

func main() {
    // ejemplo de implementacion
	circulo := circle{radio: 5}
        rectangulo := rectangle{width: 5.5, height: 4.4}

	medidas(circulo)
	medidas(rectangulo)
}
```

Esto mostraría en pantalla algo como:

```sh
78.53981633974483
31.41592653589793

24.200000000000003
19.8
```

Tal como describe los comentarios del código, en Go no tenemos clases ni mucho menos
Métodos que se definen dentro de una clase; lo más cercano a eso son las
llamadas `structs` que son algo así como un tipo de dato definido por el
usuario, el cual contiene colecciones de campos.

En Go no hay palabras claves como `implements` que indique que una `struct` esta implementando
una interfaz, en su lugar es suficiente con que se definan métodos para la `struct` que cumplan con 
la firma de métodos indicada por la interfaz. Una vez que una `struct` cumpla con todos los métodos
requeridos por una `interface`, entonces se podría decir que esa `struct` implementa la `interface`.


# Ejemplo en Ruby

Ruby, a pesar de que es un lenguaje orientado a objetos y de hacer énfasis en que todo en Ruby es un objeto, este no
tiene conceptos directos de interfaz como en lenguajes como Java, Go y similares.

Esto no nos impide que no podamos al menos emular una interfaz; sin embargo, el resultado no es tan óptimo
como en lenguajes donde sí implementen los conceptos de interfaz.

## Emulación de interfaz con módulos

El siguiente ejemplo muestra la emulación de una interfaz mediante un módulo ruby.


Lenguaje: **Ruby**
```ruby {linenos=table,anchorlinenos=true}
# Interfaz usando Modulos en Ruby.
module Geometria
  def area # firma del metodo area()
    raise 'No implementado'  # si una clase no implementa el metodo, obtendra esta excepción 
  end

  def perimetro # firma del metodo perimetro()
    raise 'No implementado'
  end
end

# Definicion de la clase Circle
class Circle
  attr_reader :radio

  # implementamos la "interfaz" Geometria
  include Geometria # nuestro equivalente ruby a la keyword implements

  def initialize(radio)
    @radio = radio
  end

  # cumplimos con la firma del metodo area
  def area
    Math::PI * radio * radio
  end

  # cumplimos con la firma del metodo perimetro
  def perimetro
    2 * Math::PI * radio
  end
end

class Rectangle
  attr_reader :width, :height # atributos del metodo Rectangle

  include Geometria

  # metodo constructor
  def initialize(width, height)
    @width = width
    @height = height
  end

  def area
    width * height
  end

  def perimetro
    2 * width + 2 * height
  end
end

# definicion del metodo medidas
def medidas(figura_geometrica)
  puts "Area: #{figura_geometrica.area}"
  puts "Perimetro: #{figura_geometrica.perimetro}"
end

circulo = Circle.new(5.0)
rectangulo = Rectangle.new(5.5, 4.4)
medidas(circulo)
medidas(rectangulo)
```

Esto mostraría en pantalla algo como:

```sh
Area: 78.53981633974483
Perimetro: 31.41592653589793

Area: 24.200000000000003
Perimetro: 19.8
```

Esto a simple vista parece una interfaz como en cualquier otro lenguaje de programación que la soporte,
pero sencillamente no es una verdadera interfaz. Verás, si por alguna razón se nos olvida
implementar un método, al llamarlo, obtendremos algo como:

```sh
interfaz.rb:3:in `area': No implementado (RuntimeError)
        from interfaz.rb:22:in `medidas'
        from interfaz.rb:27:in `<main>'
```

Pero esto solo ocurre si llamamos a ese método, no vamos a obtener una excepción o advertencia antes de ejecutar
el código, lo que derrumba por completo el propósito de una interfaz.


## Emulación de interfaz con Duck Typing


Lenguaje: **Ruby**
```ruby {linenos=table,anchorlinenos=true}
# Esta clase vendria siendo nuestra interfaz
class Geometria
  def area # firma del metodo area()
    raise 'No implementado'
  end

  def perimetro # firma del metodo perimetro()
    raise 'No implementado'
  end
end

# Heredamos caracteristicas de la clase Geometria
class Circle < Geometria
  attr_reader :radio

  def initialize(radio)
    @radio = radio
  end

  # Redefinimos el metodo area() para cumplir con el comportamiento esperado.
  def area
    Math::PI * radio * radio
  end

  def perimetro
    2 * Math::PI * radio
  end
end

class Rectangle < Geometria
  attr_reader :width, :height

  def initialize(width, height)
    @width = width
    @height = height
  end

  def area
    width * height
  end

  def perimetro
    2 * width + 2 * height
  end
end

def medidas(figura_geometrica)
  puts "Area: #{figura_geometrica.area}"
  puts "Perimetro: #{figura_geometrica.perimetro}"
end

circulo = Circle.new(5.0)
rectangulo = Rectangle.new(5.5, 4.4)
medidas(circulo)
medidas(rectangulo)
```

Esto mostraría en pantalla algo como:


```sh
Area: 78.53981633974483
Perimetro: 31.41592653589793

Area: 24.200000000000003
Perimetro: 19.8
```

Este segundo ejemplo en Ruby es muy similar al primero, la única diferencia acá es que, en lugar de módulos, usamos una clase común que
vendría a emular la interfaz `Geometria`. En lugar de incluir un módulo, lo que hacemos es heredar características de la clase `Geometria`
y mediante polimorfismo, sobreescribimos el comportamiento de los métodos heredados para así implementar el comportamiento deseado.

Acá ya se pierde un poco la semejanza a una interfaz y parece más a que estamos apoyándonos en Herencia y Polimorfismo. Esto de nuevo es debido a
que Ruby no posee definiciones de interfaz como en otros lenguajes, además de que Ruby no es un lenguaje tipado.

Al usar Duck Typing nos enfocamos más en el comportamiento de un objeto y no tanto a la clase a la que pertenece.
