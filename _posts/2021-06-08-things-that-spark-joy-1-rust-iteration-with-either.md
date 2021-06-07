---
date: 2021-06-08 09:00:00
title: "Things That Spark Joy #1: Rust Iteration with Either"
layout: post
started: 2020-06-07 16:33:00
tags: []
---

Consider a situation where you want to iterate over a list (or some other iterable data structure), but in a programmatically-defined direction. Specifically, in a direction defined by some enumerated type.

```rust
enum Flag {
    A,
    B,
}

let flag: Flag = /* ... */

match flag {
    Flag::A => {
        for elem in list.iter() {
            /* lots of complicated logic... */
        }
    },
    Flag::B => {
        for elem in list.iter().rev() {
            /* the same complicated logic... */
        }
    }
}
```

The most obvious issue here is that this code isn't very [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself). Imagine that the bodies of each `for` loop are both:

 - identical
 - very lengthy (a problem in its own right, but a separate one)

So, let's refactor our current code by extracting the iterator out. This way we won't have duplicate loops.

```rust
let my_iter = match flag {
    Flag::A => list.iter(),
    Flag::B => list.iter().rev(),
}

for elem in my_iter {
    /* lots of complicated logic... */
}
```

This makes sense, right? Well, the issue here is that this won't compile! Note that the arms of our `match` have differing types, which is not allowed (hint: think about what type you'd assign `my_iter` if you were to annotate this explicitly).

This is where [`itertools::Either`](https://docs.rs/itertools/0.10.0/itertools/enum.Either.html) saves the day (my Rust code is starting to become a Haskell DSL at this point). Now, we can write this:

```rust
let my_iter = match flag {
    Flag::A => Either::Left(list.iter()),
    Flag::B => Either::Right(list.iter().rev()),
}

for elem in my_iter {
    /* lots of complicated logic... */
}
```

This code *does* compile and works as you'd expect.

Still, perhaps you're having the same thoughts that I had when I wrote this and had everything magically work: how does the compiler know that `my_iter` implements `IntoIter`? Well, this is where Rust's extremely expressive type system truly shines.

If we consult the [actual code](https://docs.rs/either/1.6.1/src/either/lib.rs.html#391) for `itertools::Either`:

```rust
/// Convert the inner value to an iterator.
///
/// ```
/// use either::*;
///
/// let left: Either<_, Vec<u32>> = Left(vec![1, 2, 3, 4, 5]);
/// let mut right: Either<Vec<u32>, _> = Right(vec![]);
/// right.extend(left.into_iter());
/// assert_eq!(right, Right(vec![1, 2, 3, 4, 5]));
/// ```
pub fn into_iter(self) -> Either<L::IntoIter, R::IntoIter>
where
    L: IntoIterator,
    R: IntoIterator<Item = L::Item>,
{
    match self {
        Left(l) => Left(l.into_iter()),
        Right(r) => Right(r.into_iter()),
    }
}
```

Isn't it an object of pure beauty? Once again, you can always just pattern match your way to victory.

