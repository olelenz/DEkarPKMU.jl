#let conf(greet, name, pathExampleGraph) = {
  set page(
    paper: "a4",
    header: align(
      right + horizon,
      "DEkarPKMU report"
    )
  )

  set par(
    justify: true, // block style
    leading: 1em,
    linebreaks: "optimized",
    first-line-indent: 10pt,
  )
  show par: set block(spacing: 1em)

  set text(
    font: "New Computer Modern",
    size: 11pt,  
  )

  grid(
    columns: (1fr, 1fr),
    figure(
      image(
        "./img/TU_Logo_kurz_RGB_schwarz.jpg", 
        width: 57%,
      )
    ),

    figure(
      image(
        "./img/DEkarP.png",
        width: 57%,
      )
    )
  )

  [#greet : #name]
  figure(
    image(
      pathExampleGraph,
      width: 57%,
    )
  )

}
