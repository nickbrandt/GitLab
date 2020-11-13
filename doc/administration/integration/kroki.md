# Kroki diagrams

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/241744) in GitLab x.y.

When [Kroki](https://kroki.io) integration is enabled and configured in
GitLab you can use it to create diagrams in AsciiDoc and Markdown documents.

## Kroki Server

When Kroki is enabled, GitLab sends diagrams to an instance of Kroki to display them as images.
You can use the free public cloud instance `https://kroki.io` or you can [install Kroki](https://docs.kroki.io/kroki/setup/install/)
on your own infrastructure.
Once you've installed Kroki, make sure to update the server URL to point to your instance.

### Docker

With Docker, run a container like this:

```shell
docker run -d --name kroki -p 8080:8000 yuzutech/kroki
```

The **Kroki URL** is the hostname of the server running the container.

The [`yuzutech/kroki`](https://hub.docker.com/r/yuzutech/kroki) image contains the following diagrams libraries out-of-the-box:

- [Bytefield](https://bytefield-svg.deepsymmetry.org/)
- [Ditaa](http://ditaa.sourceforge.net)
- [Erd](https://github.com/BurntSushi/erd)
- [GraphViz](https://www.graphviz.org/)
- [Nomnoml](https://github.com/skanaar/nomnoml)
- [PlantUML](https://github.com/plantuml/plantuml)
  - [C4 model](https://github.com/RicardoNiepel/C4-PlantUML) (with PlantUML)
- [Svgbob](https://github.com/ivanceras/svgbob)
- [UMlet](https://github.com/umlet/umlet)
- [Vega](https://github.com/vega/vega)
- [Vega-Lite](https://github.com/vega/vega-lite)
- [WaveDrom](https://wavedrom.com/)

If you want to use additional diagram libraries,
read the [Kroki installation](https://docs.kroki.io/kroki/setup/install/#_images) to learn how to start Kroki companion containers. 

## Enable Kroki in GitLab **(CORE ONLY)**

You need to enable Kroki integration from Settings under Admin Area.
To do that, log in with an Admin account and follow these steps:

1. Select the Admin Area (**{admin}**) icon.
1. Navigate to **Settings > General**.
1. Expand the **Kroki** section.
1. Select **Enable Kroki** checkbox.
1. Enter the **Kroki URL**.

## Create diagrams

With Kroki integration enabled and configured, you can start adding diagrams to
your AsciiDoc or Markdown documentation using delimited blocks:

- **Markdown**

  ````markdown
  ```plantuml
  Bob -> Alice : hello
  Alice -> Bob : hi
  ```
  ````

- **AsciiDoc**

  ```plaintext
  [plantuml]
  ....
  Bob->Alice : hello
  Alice -> Bob : hi
  ....
  ```

The above blocks are converted to an HTML image tag with source pointing to the
Kroki instance. If the Kroki server is correctly configured, this should
render a nice diagram instead of the block:

<img src="https://kroki.io/plantuml/svg/eNpzyk9S0LVTcMzJTE5VsFLISM3JyeeC8IDCTkBZoGAmANl1Cxw="/>

Kroki supports more than a dozen diagram libraries. Here's a few examples:

**GraphViz**

```plaintext
[graphviz]
....
digraph finite_state_machine {
  rankdir=LR;
  node [shape = doublecircle]; LR_0 LR_3 LR_4 LR_8;
  node [shape = circle];
  LR_0 -> LR_2 [ label = "SS(B)" ];
  LR_0 -> LR_1 [ label = "SS(S)" ];
  LR_1 -> LR_3 [ label = "S($end)" ];
  LR_2 -> LR_6 [ label = "SS(b)" ];
  LR_2 -> LR_5 [ label = "SS(a)" ];
  LR_2 -> LR_4 [ label = "S(A)" ];
  LR_5 -> LR_7 [ label = "S(b)" ];
  LR_5 -> LR_5 [ label = "S(a)" ];
  LR_6 -> LR_6 [ label = "S(b)" ];
  LR_6 -> LR_5 [ label = "S(a)" ];
  LR_7 -> LR_8 [ label = "S(b)" ];
  LR_7 -> LR_5 [ label = "S(a)" ];
  LR_8 -> LR_6 [ label = "S(b)" ];
  LR_8 -> LR_5 [ label = "S(a)" ];
}
....
```

<img src="https://kroki.io/graphviz/svg/eNqFzr0OgjAUBeCZPsUNccDBRH6EJgQTnZlgJIYUWqURCwGcjO8uGAwUVJYzffecS_mlImUGZy54w-K6IW3eSJpxweCBlIqIK-WV5wcuUkRBGUR1RkoGHtDinuQs5VWas5MLfhBvuzC7sLrAs5MPRspbb_YdMyCCnCQsb4EahtpxrcKE6BMSDkTviSkRbcUEHZDRI3vSk8zJbkLInFjy1GEQu144skjmQp4Zr9hffx132IsdTi_wzw5nsQMv_oH_djzRC38unS8="/>

**C4 (based on PlantUML)**

```plaintext
[c4plantuml]
....
@startuml
!include C4_Context.puml

title System Context diagram for Internet Banking System

Person(customer, "Banking Customer", "A customer of the bank, with personal bank accounts.")
System(banking_system, "Internet Banking System", "Allows customers to check their accounts.")

System_Ext(mail_system, "E-mail system", "The internal Microsoft Exchange e-mail system.")
System_Ext(mainframe, "Mainframe Banking System", "Stores all of the core banking information.")

Rel(customer, banking_system, "Uses")
Rel_Back(customer, mail_system, "Sends e-mails to")
Rel_Neighbor(banking_system, mail_system, "Sends e-mails", "SMTP")
Rel(banking_system, mainframe, "Uses")
@enduml
....
```

<img src="https://kroki.io/c4plantuml/svg/eNp9UkFuwjAQvOcVW05Uopz6AErEgQMVKvQcGbNJLBwbeTeC_r4b40AQtLd4PDszO86MWAVuG5u9GKdtu0fI34vcO8YzT4_dRcaGLcLmhxgbSFewN6oKqoHSB1gKFBwyzJU7GFclbpatMZB3Y90S-wbDBEY9I0_QSLAP6AngS-AaYSesCZwM13CMEspGDJTWvnVM09FrdjEZ7y6KBcWjyP2RJjpZ6090tSNgD7pGfehcTbiTT_rF4szjRhl7M1i8dWegq-xWIpvoKjlXRgdPvmRYnHWtXIWAw4Fb9F7alVIkis6q_34SfcM-IIGyti9JCwBpe7GXh2gUG-9i-C-0g9ofOvomJKEJq5grfRhQ71fdoNtTyt-1lWY-0VT1zoeH8v-ZjkustuuLxLPJaw8p3UzG5Qf8BSot7V4="/>

**Nomnoml**

```plaintext
[nomnoml]
....
[Pirate|eyeCount: Int|raid();pillage()|
  [beard]--[parrot]
  [beard]-:>[foul mouth]
]

[<abstract>Marauder]<:--[Pirate]
[Pirate]- 0..7[mischief]
[jollyness]->[Pirate]
[jollyness]->[rum]
[jollyness]->[singing]
[Pirate]-> *[rum|tastiness: Int|swig()]
[Pirate]->[singing]
[singing]<->[rum]
....
```

<img src="https://kroki.io/nomnoml/svg/eNpdjzELgzAQhff8ioxaSOlWsJKlU4dC95Dh1Kgp0cjlQhH88VWs1BZueLz73j1OPSwCmcmM5upjTxm_9TQh2CpJL4N1DhqTpBPjXBUGsNJCqAEQPemdl0lV--h45yO1mmnGVA5FIISS5B0QYmVQ59kcXvs024Tgp-PxrDobytaael48vXNjb0LQQn7xHxdj928F2zfz7A5LfljAiSCQXbD1t_CyTZLuuV12U_mn5A2ROWWs"/>
