# Example Title

## Introduction

This is an example markdown you can use to test porting a markdown to Canvas.

Since this markdown is not the default `README.md`, to convert this markdown,
you should use a command like:

```sh
github-to-canvas -c <course_id> --file EXAMPLE.md
```

If Canvas lesson creation is successful, the gem will output a link you can use
to go directly to the new lesson.

## Example Code Blocks

### JavaScript

```js
const variable = "string" + 23;

// comment
function hello(world) {
  if (true) {
    console.log(world);
  }
  return null;
}
```

### JSX

```jsx
import React from "react";

function App({ props }) {
  return (
    <div>
      {/* comment */}
      <Header name={props.name} />
    </div>
  );
}
```

### HTML

```html
<body>
  <!-- comment -->
  <div id="container">
    <h1>Hello</h1>
    <h2>World</h2>
  </div>
</body>
```

### Ruby

```rb
# Comment
class Dog < ActiveRecord::Base
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def woof
    puts "Woof my name is #{self.name}"
  end

end

dog = Dog.new("Fezzik")
dog.woof
```

### CSS

```css
/* Fixes size issue for inline code in headings */
#content .user_content h1 code,
#content .user_content h2 code,
#content .user_content h3 code,
#content .user_content h4 code,
#content .user_content h5 code,
#content .user_content h6 code {
  font-size: 0.8em;
  padding: 0.2em 0.4em;
  color: inherit;
}
```

### SQL

```sql
-- comment
SELECT
  title AS name,
  genre,
  price
FROM games
INNER JOIN reviews ON games.id = reviews.game_id
WHERE reviews.score > 4;
```

### Python

```python
def bubble_sort(items):
    """ Implementation of bubble sort """
    for i in range(len(items)):
        for j in range(len(items)-1-i):
            if items[j] > items[j+1]:
                # Swap!
                items[j], items[j+1] = items[j+1], items[j]
```

### SH

```sh
bundle exec rails db:migrate db:seed
bundle exec rails server
```

### Plaintext

```txt
const variable = "string" + 23;

// comment
function hello(world) {
  if (true) {
    console.log(world);
  }
  return null;
}
```

### Indented Code Blocks

    Four spaces also produces a code block
    (fence code blocks are preferred tho)

## Tables

| Syntax    | Description |
| --------- | ----------- |
| Header    | Title       |
| Paragraph | Text        |

Table with alignment (left, center, right):

| Syntax    | Description |   Test Text |
| :-------- | :---------: | ----------: |
| Header    |    Title    | Here's this |
| Paragraph |    Text     |    And more |

---

# Heading Level 1

## Heading Level 2

### Heading Level 3

#### Heading Level 4

##### Heading Level 5

###### Heading Level 6

## Heading with `inline code`

Here are some `inline` `<code>` `<h1>blocks</h1>`

## Example Images

Here are some image examples:

### Inline Markdown

![example in-line image](https://curriculum-content.s3.amazonaws.com/fewpjs/fewpjs-fetch-lab/Image_25_AsynchronousJavaScript.png)

![Tower of Babel](http://www.ancient-origins.net/sites/default/files/field/image/tower-of-babel-2.jpg)

### Embedded in HTML

<p align="center">
  <img src="https://curriculum-content.s3.amazonaws.com/fewpjs/fewpjs-fetch-lab/Image_25_AsynchronousJavaScript.png" width="500">
</p>

## Emphasis

Here is some **bold text** and some _emphasized text_.

Here is some text with underscores in_side_the text that shouldn't be emphasized.

For example, this snake case variable should have underscores: `snake_case_variable`

## Quotes

A single paragraph quote:

> Dorothy followed her through many of the beautiful rooms in her castle.

A multi-paragraph quote:

> Dorothy followed her through many of the beautiful rooms in her castle.
>
> The Witch bade her clean the pots and kettles and sweep the floor and
> keep the fire fed with wood.

A nested quote:

> Dorothy followed her through many of the beautiful rooms in her castle.
>
> > The Witch bade her clean the pots and kettles and sweep the floor and
> > keep the fire fed with wood.

A quote with other elements:

> #### The quarterly results look great!
>
> - Revenue was off the chart.
> - Profits were higher than ever.
>
>   _Everything_ is going according to **plan**.

## Lists

### Unordered

- First item
- Second item
- Third item
  - Indented item
  - Indented item
- Fourth item

### Ordered

1. First item
2. Second item
3. Third item
   1. Indented item
   2. Indented item
4. Fourth item

### (doesn't render correctly) Unordered with nested paragraph

- This is the first list item.
- Here's the second list item.

  I need to add another paragraph below the second list item.

- And here's the third list item.

### (doesn't render correctly) Ordered with nested paragraph

1. This is the first list item.

2. Here's the second list item.

   I need to add another paragraph below the second list item.

   ```js
   const code = "mixed in with the list";
   ```

3. And here's the third list item.

## Links

A typical markdown link: [example](http://example.com)

A reference style link: [example][]

[example]: http://example.com

A link with a title: [titled link](http://example.com "example title")

### A Header With A [Link](http://example.com)
