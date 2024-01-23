#let conf(id, name, pathEigenverbrauch, pathAutarkiegrad, pathDuplicate, outputData) = {
  set page(
    paper: "a4",
    header: [
      #set text(8pt)
      #smallcaps[Referenznummer: #id]
      #h(1fr) _DEkarPKMU report_
    ],
    footer: [
      #set text(8pt)
      #grid(
        columns: (33%, 33%, 33%),
        align(bottom + center, figure(
          image(
            "./img/TU_Logo_kurz_RGB_schwarz.jpg", 
            width: 30%,
          )
        )),
        align(bottom + center, counter(page).display(
          "1 of I",
          both: true,
        )),
        align(bottom + center, figure(
          image(
            "./img/DEkarP.png",
            width: 30%,
          )
        ))
      )
    ]
  )

  set par(
    justify: true, // block style
    leading: 1em,
    linebreaks: "optimized",
    //first-line-indent: 10pt,
  )
  show par: set block(spacing: 1em)

  set text(
    font: "New Computer Modern",
    size: 9pt,  
  )

  align(center, text(17pt)[
    *A fluid dynamic model
    for glacier flow*
  ])
  text(size: 13pt, weight: "bold")[Input:]
  linebreak()
  text(size: 13pt, weight: "bold")[Kennzahlen:]
  linebreak()
  set terms(indent: 7pt)
  let num(var) = {
    [#align(right, [#outputData.at(var)#h(0.2cm)])]
  }
  grid(
    columns: (5cm, 5cm, 2cm),
    rows: (15pt, 15pt, 15pt),
    [Leistung Elektrolyse:],
    [#num("LeistungElektrolyse")],
    [kW],
    [Leistung Brennstoffzelle:],
    [#num("LeistungBrennstoffzelle")],
    [kW],
    [Wasserstofftankfüllstand:],
    [#num("Wasserstofftankfuellstand")],
    [avg unit?],
    [Verkaufter Strom:],
    [#num("VerkaufterStrom")],
    [kW],
    [Eingekaufter Strom:],
    [#num("EingekaufterStrom")],
    [kW],
    [Batterie Input:],
    [#num("BatterieInput")],
    [kWh],
    [Verwendete Energie:],
    [#num("VerwendeteEnergie")],
    [kW],

  )
  
  
  grid(
    columns: (1fr, 1fr),
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
    )
  )

  figure(
    image(
      pathDuplicate,
      width: 90%,
    )
  )

}
