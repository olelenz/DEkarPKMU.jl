#let conf(id, name, pathEigenverbrauch, pathAutarkiegrad, pathLastverlauf, inputData, outputData) = {
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
    justify: true,
    leading: 1em,
    linebreaks: "optimized",
  )
  show par: set block(spacing: 1em)

  set text(
    font: "New Computer Modern",
    size: 9pt,  
  )

  align(center, text(17pt)[
    *DEkarPKMU Reporting*
  ])
  text(size: 13pt, weight: "bold")[Input:]
  let num(var) = {
     [#align(right, [#outputData.at(var)#h(0.2cm)])]
  }
  let numIn(var) = {
     [#align(right, [#inputData.at(var)#h(0.2cm)])]
  }
  let flag(var) = {
    if inputData.at(var) [#align(right, [Ja])] else [#align(right, [Nein])]
  }
  grid(
    columns: (5cm, 2cm, 2cm, 5cm, 2cm, 2cm),
    rows: (15pt, 15pt, 15pt, 15pt, 15pt, 15pt),
    [WACC:],
    [#numIn("WACC")],
    [kW],
    [Inflationsfaktor:],
    [#numIn("inflation")],
    [%],
    [Projektlaufzeit:],
    [#numIn("Projektlaufzeit")],
    [Jahre],
    [Wind:],
    [#flag("Wind")],
    [],
    [Photovoltaik:],
    [#flag("PV")],
    [],
    [Batterie:],
    [#flag("Batterie")],
    [],
    [H2-Speichersystem:],
    [#flag("H2")],
    [],
    [PV Flächenverfügbarkeit:],
    [#numIn("PVFlaeche")],
    [$m^2$],
    [Windernergieanlage Fläche:],
    [#numIn("WTFlaeche")],
    [$m^2$],
    [Windernergie Höhenbegrenzung:],
    [#align(right, [Nein])],
    [],
    [Ges. Stromverbrauch:],
    [#numIn("GesStromverbrauch")],
    [kW],
    [Schichten:],
    [#numIn("Schichten")],
    [],
    [Strompreis Einkauf:],
    [#numIn("StrompreisEinkauf")],
    [$"€"/"kWh"$],
    [Strompreis Verkauf:],
    [#numIn("StrompreisVerkauf")],
    [$"€"/"kWh"$],
    [Netzentgelt:],
    [#numIn("Netzentgelt")],
    [$"€"/"kWh"$],
    [Fernwärmepreis:],
    [#numIn("Fernwaermepreis")],
    [$"€"/"kWh"$],
    [Lastverlauf verschoben:],
    [#align(right, [Nein])],
    [],

  )

  linebreak()
  text(size: 13pt, weight: "bold")[Kennzahlen:]
  linebreak()
  grid(
    columns: (5cm, 2cm, 2cm, 5cm, 2cm, 2cm),
    rows: (15pt, 15pt, 15pt, 15pt, 15pt, 15pt),
    [Leistung Elektrolyse:],
    [#num("LeistungElektrolyse")],
    [kW],
    [Leistung Brennstoffzelle:],
    [#num("LeistungBrennstoffzelle")],
    [kW],
    [Wasserstofftankfüllstand:],
    [#num("Wasserstofftankfuellstand")],
    [],
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
    [Kapazität Wasserstofftank:],
    [#num("KapazitaetWasserstofftank")],
    [],
    [Kapazität Batterie:],
    [#num("KapazitaetBatterie")],
    [],
    [],
    [],
    [],

    [],
    [],
    [],
    [],
    [],
    [],

    [Gesamte Energiekosten:],
    [#num("GesamteEnergiekosten")],
    [€],
    [Kapitalwert:],
    [#num("NPV")],
    [€],
    [Investitionen:],
    [#num("Investitionen")],
    [€],
    [Restwerte:],
    [#num("Restwerte")],
    [€],
    [Annuitätenfaktor:],
    [#numIn("Annuitaetenfaktor")],
    [],

  )

//[Gesamte Energiekosten = (Kapitalwert + Investitionen - Restwerte) times Annuitätenfaktor]

  figure(
    image(
      pathLastverlauf,
      width: 98%,
    )
  )
  grid(
    columns: (1fr, 1fr),
    figure(
      image(
        pathEigenverbrauch,
        width: 70%,
      )
    ),
    figure(
      image(
        pathAutarkiegrad,
        width: 70%,
      )
    )
  )


}
