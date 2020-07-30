---
description: 'Learn how to install GitLab onto a Microsoft Azure Linux VM.'
type: howto
---

# Install GitLab on Microsoft Azure

GitLab's self-managed, Omnibus installation makes installing GitLab into a Microsoft Azure ecosystem an easy task. This guide aims to cover how to install and configure GitLab on your preferred Linux distribution in Microft Azure.

NOTE: **GitLab is Coming Soon to the Azure Marketplace:**
We are currently working on a solution that will bring GitLab to the Azure Marketplace to ease the burden of installing, configuring and maintaining it. Be sure to [follow the issue](https://gitlab.com/gitlab-com/alliances/microsoft/gitlab-tracker/-/issues/2) to get the latest updates.

## Selecting a Linux distribution

Azure Virtual Machines (VM) are on-demand, scalable computing resources in Azure.  When installing GitLab, we recommend using [one of the many endorsed Linux distributions](https://azure.microsoft.com/en-us/overview/linux-on-azure/#supported-distributions).

Your Linux distribution of choice installing on an Azure VM can help provide the benefits of virtualized compute resources. When using an Azure VM, you are responsible for the maintenance of the operating system and GitLab services will also need to be configured and maintained.

For sizing specifications of the VM, you can use our [Reference Architecture documentation](https://docs.gitlab.com/ee/administration/reference_architectures/index.html#available-reference-architectures) to determine the appropriate size for your needs.

## Installing Omnibus GitLab

Once you have been able to provision a Linux VM in Azure and have access to the host, you can refer to our [Omnibus Documentation](https://about.gitlab.com/install/) to complete the installation. Be sure to select the documentation aligned with your selected Linux Distribution.

## Using GitLab CI/CD

When using GitLab CI, we recommend using compute resources on a host separate from the primary GitLab host. You can refer to our [GitLab Runner installation documentation](https://docs.gitlab.com/runner/install/) for suggestions on how to proceed.

## Conclusion

Naturally, we believe that GitLab is a great Git repository tool. However, GitLab is a whole lot
more than that too. GitLab unifies issues, code review, CI and CD into a single UI, helping you to
move faster from idea to production, and in this tutorial we showed you how quick and easy it is to
set up and run your own instance of GitLab on Azure, Microsoft's cloud service.

Azure is a great way to experiment with GitLab, and if you decide (as we hope) that GitLab is for
you, you can continue to use Azure as your secure, scalable cloud provider or of course run GitLab
on any cloud service you choose.

## Where to next?

Check out our other [Technical Articles](../../articles/index.md) or browse the [GitLab Documentation](../../README.md) to learn more about GitLab.

### Useful links

- [GitLab Community Edition](https://about.gitlab.com/features/)
- [GitLab Enterprise Edition](https://about.gitlab.com/features/#ee-starter)
- [Microsoft Azure](https://azure.microsoft.com/en-us/)
  - [Azure - Free Account FAQ](https://azure.microsoft.com/en-us/free/free-account-faq/)
  - [Azure - Marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/)
  - [Azure Portal](https://portal.azure.com)
  - [Azure - Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
  - [Azure - Troubleshoot SSH Connections to an Azure Linux VM](https://docs.microsoft.com/en-us/azure/virtual-machines/troubleshooting/troubleshoot-ssh-connection)
  - [Azure - Properly Shutdown an Azure VM](https://build5nines.com/properly-shutdown-azure-vm-to-save-money/)
- [SSH](https://en.wikipedia.org/wiki/Secure_Shell), [PuTTY](https://www.putty.org) and [Using SSH in PuTTY](https://mediatemple.net/community/products/dv/204404604/using-ssh-in-putty-)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
