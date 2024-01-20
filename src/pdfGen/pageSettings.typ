#let conf(greet, name, pathEigenverbrauch, pathAutarkiegrad, pathDuplicate) = {
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
  grid(
    columns: (1fr, 1fr, 1fr),
    figure(
      image(
        pathEigenverbrauch,
        width: 90%,
      )
    ),
    figure(
      image(
        pathAutarkiegrad,
        width: 90%,
      )
    ),
    figure(
      image(
        pathDuplicate,
        width: 90%,
      )
    )
  )

}
