# frozen_string_literal: true

FactoryBot.define do
  factory :evidence do
    release

    trait :with_summary do
      summary do
        {
          id: 1,
          tag: 'v7.20.0',
          name: 'new release',
          project: {
            id: 8,
            name: 'Html5 Boilerplate',
            created_at: '2019-09-20T06:25:49.212Z',
            description: 'Sit eius quia dignissimos qui et minima.'
          },
          created_at: '2019-09-20T12:27:52.530Z',
          milestones: [
            {
              id: 40,
              state: 'closed',
              title: 'v4.0',
              issues: [
                {
                  id: 72,
                  state: 'opened',
                  title: 'Consequuntur tempore culpa magni vel.',
                  author: {
                    id: 8,
                    name: 'Sina Hegmann',
                    email: 'elvira@collier.co.uk'
                  },
                  due_date: nil,
                  created_at: '2019-09-17T06:26:23.160Z',
                  description: 'Laborum sint expedita dolorem tempore.',
                  confidential: false
                },
                {
                  id: 68,
                  state: 'opened',
                  title: 'Aut quidem non et a vero recusandae saepe atque dolor sed.',
                  author: {
                    id: 20,
                    name: 'Lacy Blick',
                    email: 'kyoko_lemke@weber.co.uk'
                  },
                  due_date: nil,
                  created_at: '2019-08-21T06:26:23.160Z',
                  description: 'Quia aliquid laboriosam possimus.',
                  confidential: false
                }
              ],
              due_date: nil,
              created_at: '2019-09-20T06:26:14.482Z',
              description: 'Atque nihil et ut sapiente eos.'
            },
            {
              id: 48,
              state: 'active',
              title: 'Sprint - Sed sit animi ut magni odit sit.',
              issues: [
                {
                  id: 218,
                  state: 'closed',
                  title: 'Explicabo officia asperiores blanditiis velit eaque magnam.',
                  author: {
                    id: 7,
                    name: 'Terry Leannon',
                    email: 'shakia.toy@koch.name'
                  },
                  due_date: nil,
                  created_at: '2019-09-10T06:30:16.095Z',
                  description: 'Minus tempora deleniti ea ipsa molestiae ipsam quia.',
                  confidential: false
                },
                {
                  id: 219,
                  state: 'closed',
                  title: 'Aut qui vel ea earum aut adipisci qui sed officiis.',
                  author: {
                    id: 21,
                    name: 'Quintin Hegmann',
                    email: 'gwen.heathcote@mcdermott.com'
                  },
                  due_date: nil,
                  created_at: '2019-09-10T06:30:16.201Z',
                  description: 'Itaque et iusto recusandae harum sapiente quia.',
                  confidential: false
                }
              ],
              due_date: '2019-09-19',
              created_at: '2019-09-10T06:30:15.607Z',
              description: 'Sequi dolor ut ducimus cum.'
            }
          ],
          description: 'another test release'
        }
      end
    end
  end
end
