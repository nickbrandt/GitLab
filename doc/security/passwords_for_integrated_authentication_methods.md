---
type: reference
---

# How we generate passwords for users created via integrated authentication methods

GitLab allows users to create accounts using different [authentication methods](../administration/auth/README.md) like OmniAuth, SAML, SCIM, Smartcard authentication etc.

These authentication methods does not require the user to explicitly create a password for their account upon signup. However, to maintain data consistency, GitLab requires each user account to have a password associated with it.

For such accounts, we use the [`friendly_token`](https://github.com/heartcombo/devise/blob/f26e05c20079c9acded3c0ee16da0df435a28997/lib/devise.rb#L492) method provided by the Devise gem to generate a random, unique and secure password and sets it as the account password during sign up.

The length of the generated password is the set based on the value of [maximum password length](password_length_limits.md#modify-maximum-password-length-using-configuration-file) as set in the Devise configuation. The default value is 128 characters.
