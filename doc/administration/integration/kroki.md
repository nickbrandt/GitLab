# Kroki & GitLab

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44851) in GitLab x.y.

When [Kroki](https://kroki.io) integration is enabled and configured in
GitLab we are able to create diagrams in AsciiDoc and Markdown documents.

## Kroki Server

When Kroki is enabled, GitLab sends diagrams to an instance of Kroki to display them as images.
You can use the free public cloud instance `https://kroki.io` or you can [install Kroki](https://docs.kroki.io/kroki/setup/install/)
on your own infrastructure.
Once you've installed Kroki, make sure to update the server URL to point to your instance.

### Docker

With Docker, you can just run a container like this:

```shell
docker run -d --name kroki -p 8080:8000 yuzutech/kroki
```

The **Kroki URL** will be the hostname of the server running the container.

[`yuzutech/kroki`](https://hub.docker.com/r/yuzutech/kroki) image contains the following diagrams libraries out-of-the-box:

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

In other words, the following endpoints will be available:

```plaintext
/bytefield
/c4plantuml
/ditaa
/erd
/graphviz
/dot
/nomnoml
/plantuml
/svgbob
/umlet
/vega
/vegalite
/wavedrom
```

If you want to use _ActDiag_, _BlockDiag_, _NwDiag_, _PacketDiag_, _RackDiag_, _SeqDiag_, _Mermaid_ or _BPMN_, then you will also need to start companion containers:

[`yuzutech/kroki-blockdiag`](https://hub.docker.com/r/yuzutech/kroki-blockdiag)

Provides block, sequence, activity and network diagrams for Kroki using respectively
[ActDiag](http://blockdiag.com/en/actdiag/index.html),
[BlockDiag](http://blockdiag.com/en/blockdiag/index.html),
[NwDiag](http://blockdiag.com/en/nwdiag/index.html),
[PacketDiag](http://blockdiag.com/en/nwdiag/packetdiag-examples.html),
[RackDiag](http://blockdiag.com/en/nwdiag/rackdiag-examples.html),
and [SeqDiag](http://blockdiag.com/en/seqdiag/index.html) libraries.

[`yuzutech/kroki-mermaid`](https://hub.docker.com/r/yuzutech/kroki-mermaid)

Provides flowchart, sequence and Gantt diagrams for Kroki using [Mermaid](https://mermaidjs.github.io).

[`yuzutech/kroki-bpmn`](https://hub.docker.com/r/yuzutech/kroki-bpmn)

Provides BPMN diagrams for Kroki using [bpmn-js](https://bpmn.io/toolkit/bpmn-js).

You can use `docker-compose` to run multiple containers.
Here's an example where we start all the containers using a `docker-compose.yml` file:

```yaml
version: "3"
services:
 core:
   image: yuzutech/kroki
   environment:
     - KROKI_BLOCKDIAG_HOST=blockdiag
     - KROKI_MERMAID_HOST=mermaid
     - KROKI_BPMN_HOST=bpmn
   ports:
     - "8000:8000"
 blockdiag:
   image: yuzutech/kroki-blockdiag
   expose:
     - "8001"
 mermaid:
   image: yuzutech/kroki-mermaid
   expose:
     - "8002"
 bpmn:
   image: yuzutech/kroki-bpmn
   expose:
     - "8003"
```

```shell
docker-compose up -d
```

## GitLab

You need to enable Kroki integration from Settings under Admin Area.
To do that, login with an Admin account and do following:

- In GitLab, go to **Admin Area > Settings > General**.
- Expand the **Kroki** section.
- Check **Enable Kroki** checkbox.
- Configure the **Kroki URL**.

## Creating Diagrams

With Kroki integration enabled and configured, we can start adding diagrams to
our AsciiDoc or Markdown documentation using delimited blocks:

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

The above blocks will be converted to an HTML image tag with source pointing to the
Kroki instance. If the Kroki server is correctly configured, this should
render a nice diagram instead of the block:

<img src="https://kroki.io/plantuml/svg/eNpzyk9S0LVTcMzJTE5VsFLISM3JyeeC8IDCTkBZoGAmANl1Cxw="/>

Kroki supports more than a dozen diagram libraries, here's a few examples:

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
