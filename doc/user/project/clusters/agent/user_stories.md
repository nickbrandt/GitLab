---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# User stories

[Personas in action](https://about.gitlab.com/handbook/marketing/product-marketing/roles-personas/#user-personas):

- Sasha, the Software Developer. Their main job is to ship business applications.
- Allison, the Application Operator. Their main job is 2nd day operations of business applications.
- Priyanka, the Platform Engineer. Their main job is to enable Allison and Sasha to do their job.

Devon, the DevOps engineer, is left out on purpose as DevOps is a bloated term that hardly fits a persona. It's more of a role.

## Stories

NOTE: **Note:**
There are various workflows to support, so some user stories might seem to contradict each other. They don't.

- As a Software Developer:
  - I want to push my code, and move to the next development task, in order to work on business apps.
  - I want to set necessary dependencies and resource requirements together with my application code, so that my code will run fine once deployed.
- As an Application Operator:
  - I want to standardize the deployments used by my teams, so that I can support all teams with minimal effort.
  - I want to have a single place to define all the deployments, so that I can assure security fixes are applied everywhere.
  - I want to offer a set of predefined templates to Software Developers, so they can get started quickly and can deploy to production without my intervention, so I'm not a bottleneck.
  - I want to know exactly what changes are being deployed, so that I can fulfill my SLAs.
  - I want deep insights into what versions of my apps are running and want to be able to debug them, so I can fix operational issues.
  - I want application code to be automatically deployed to staging environments when new versions are available.
  - I want to follow my preferred deployment strategy, so that I can move code into production in a reliable way.
  - I want review every code before it gets deployed into production, so that I can fulfill my SLAs.
  - I want to be notified when new code needs my attention before deployment, so that I can review it swiftly.
- As a Platform Engineer:
  - I want to restrict customizations to preselected values for Operators, so that I can fulfill my SLAs.
  - I want to allow some level of customization to Operators, so I won't become a bottleneck.
  - I want to have a single place to define all the deployments, so that I can assure security fixes are applied everywhere.
  - I want to define the infrastructure by code, so that I can have testable, reproducible, traceable, and scalable infrastructure management.
  - I want to define various policies that applications should follow, so that I can fulfill my SLAs.
  - I want approved tooling around log management and persistent storage, so that I can scale, secure, and manage them as needed.
  - I want to be alerted when my infrastructure differs from its definition, so I can make sure that everything is set up as expected.
