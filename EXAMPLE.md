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

```js
function hello(world) {
  console.log(world);
}
```

```jsx
function App({ props }) {
  return (
    <div>
      {/* comment */}
      <Header name={props.name} />
    </div>
  )
}
```

```html
<h1>Hello</h1>
<h2>World</h2>
```

```rb
redcarpet = Redcarpet::Markdown.new(CustomRender, tables: true, autolink: true, fenced_code_blocks: true, disable_indented_code_blocks: true)
html = redcarpet.render(markdown)
```

```css
body {
  color: red;
}
```

Here are some `inline` `<code>` `<h1>blocks</h1>`

## Example Images

Here are some image examples:

### Inline Markdown

![example in-line image](https://curriculum-content.s3.amazonaws.com/fewpjs/fewpjs-fetch-lab/Image_25_AsynchronousJavaScript.png)

![Tower of Babel](http://www.ancient-origins.net/sites/default/files/field/image/tower-of-babel-2.jpg)

### HTML

#### Embeded in other HTML

<p align="center">
  <img src="https://curriculum-content.s3.amazonaws.com/fewpjs/fewpjs-fetch-lab/Image_25_AsynchronousJavaScript.png" width="500">
</p>

#### Embedded in Markdown Table

| <img src="images/mongo-db-logo.png" height=60% width=60%> | <img src="images/couchbase-logo.png"> |
|---------------------|---------------------|

#### Single/Double Quotes, With or Without Attributes

<img src="images/couchbase-logo.png">
<img src="images/couchbase-logo.png" width=50%>
<img src='images/couchbase-logo.png'>
<img src='images/couchbase-logo.png' width=50%>
