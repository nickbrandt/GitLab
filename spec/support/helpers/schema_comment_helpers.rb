# frozen_string_literal: true

module SchemaCommentHelpers
  def expect_function_to_have_comment(name, text)
    name = connection.quote(name)
    catalog_name = connection.quote('pg_proc')

    comment = connection.select_value(<<~SQL)
      SELECT obj_description(
        (
          SELECT oid
          FROM pg_catalog.pg_proc
          WHERE proname = #{name}
        ),
        #{catalog_name}
      )
    SQL

    expect(comment).to eq(text)
  end
end
