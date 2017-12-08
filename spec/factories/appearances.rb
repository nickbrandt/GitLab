# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :appearance do
<<<<<<< HEAD
    title "GitLab Enterprise Edition"
    description "Open source software to collaborate on code"
    new_project_guidelines "Custom project guidelines"
||||||| merged common ancestors
    title       "MepMep"
    description "This is my Community Edition instance"
=======
    title       "MepMep"
    description "This is my Community Edition instance"
    new_project_guidelines "Custom project guidelines"
>>>>>>> ce/10-3-stable
  end
end
