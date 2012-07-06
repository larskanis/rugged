# encoding: UTF-8
require "test_helper"

context "Rugged::Branch.each" do
  setup do
    @path = temp_repo("testrepo.git")
    @repo = Rugged::Repository.new(@path)
  end

  test "lists the names of all branches in a bare repository" do
    list = Rugged::Branch.each(@repo).sort
    assert_equal [
      "master",
      "origin/HEAD",
      "origin/master",
      "origin/packed"
    ], list
  end
end

context "Rugged::Branch.find" do
  setup do
    @path = temp_repo("testrepo.git")
    @repo = Rugged::Repository.new(@path)
  end

  test "can look up local branches" do
    branch = Rugged::Branch.find(@repo, "master")
    refute_nil branch

    assert_equal "master", branch.name
    assert_equal "refs/heads/master", branch.canonical_name
    assert_equal "36060c58702ed4c2a40832c51758d5344201d89a", branch.tip.oid
  end

  test "can look up a local branch by its canonical name" do
    branch = Rugged::Branch.find(@repo, "refs/heads/master")
    refute_nil branch

    assert_equal "master", branch.name
    assert_equal "refs/heads/master", branch.canonical_name
    assert_equal "36060c58702ed4c2a40832c51758d5344201d89a", branch.tip.oid
  end

  test "can look up remote branches" do
    branch = Rugged::Branch.find(@repo, "origin/packed")
    refute_nil branch

    assert_equal "origin/packed", branch.name
    assert_equal "refs/remotes/origin/packed", branch.canonical_name
    assert_equal "41bc8c69075bbdb46c5c6f0566cc8cc5b46e8bd9", branch.tip.oid
  end

  test "can look up a local branch by its canonical name" do
    branch = Rugged::Branch.find(@repo, "refs/remotes/origin/packed")
    refute_nil branch

    assert_equal "origin/packed", branch.name
    assert_equal "refs/remotes/origin/packed", branch.canonical_name
    assert_equal "41bc8c69075bbdb46c5c6f0566cc8cc5b46e8bd9", branch.tip.oid
  end

  test "can look up branches with non 7-bit ASCII characters" do
    new_branch = @repo.create_branch("Ångström", "5b5b025afb0b4c913b4c338a42934a3863bf3644")
    refute_nil new_branch

    retrieved_branch = Rugged::Branch.find(@repo, "Ångström")
    refute_nil retrieved_branch

    assert_equal new_branch, retrieved_branch
  end
end

context "Rugged::Repository#create_branch" do
  setup do
    @path = temp_repo("testrepo.git")
    @repo = Rugged::Repository.new(@path)
  end

  test "can create a new branch" do
    new_branch = @repo.create_branch("test_branch", "5b5b025afb0b4c913b4c338a42934a3863bf3644")

    refute_nil new_branch
    assert_equal "test_branch", new_branch.name
    assert_equal "refs/heads/test_branch", new_branch.canonical_name

    refute_nil new_branch.tip
    assert_equal "5b5b025afb0b4c913b4c338a42934a3863bf3644", new_branch.tip.oid

    refute_nil @repo.branches.find { |p| p.name == "test_branch" }
  end

  test "can create branches with non 7-bit ASCII names" do
    new_branch = @repo.create_branch("Ångström", "5b5b025afb0b4c913b4c338a42934a3863bf3644")

    refute_nil new_branch
    assert_equal "Ångström", new_branch.name
    assert_equal "refs/heads/Ångström", new_branch.canonical_name

    refute_nil new_branch.tip
    assert_equal "5b5b025afb0b4c913b4c338a42934a3863bf3644", new_branch.tip.oid

    refute_nil @repo.branches.find { |p| p.name == "Ångström" }
  end

  test "can create a new branch with an abbreviated sha" do
    new_branch = @repo.create_branch("test_branch", "5b5b025")

    refute_nil new_branch
    assert_equal "test_branch", new_branch.name
    assert_equal "refs/heads/test_branch", new_branch.canonical_name

    refute_nil new_branch.tip
    assert_equal "5b5b025afb0b4c913b4c338a42934a3863bf3644", new_branch.tip.oid
  end

  test "can create a new branch from a tag name" do
    new_branch = @repo.create_branch("test_branch", "refs/tags/v0.9")

    refute_nil new_branch
    assert_equal "test_branch", new_branch.name
    assert_equal "refs/heads/test_branch", new_branch.canonical_name

    refute_nil new_branch.tip
    assert_equal "5b5b025afb0b4c913b4c338a42934a3863bf3644", new_branch.tip.oid
  end

  test "can create a new branch from implicit head" do
    new_branch = @repo.create_branch("test_branch")

    refute_nil new_branch
    assert_equal "test_branch", new_branch.name
    assert_equal "refs/heads/test_branch", new_branch.canonical_name

    refute_nil new_branch.tip
    assert_equal "36060c58702ed4c2a40832c51758d5344201d89a", new_branch.tip.oid
  end

  test "can create a new branch from explicit head" do
    new_branch = @repo.create_branch("test_branch", "HEAD")

    refute_nil new_branch
    assert_equal "test_branch", new_branch.name
    assert_equal "refs/heads/test_branch", new_branch.canonical_name

    refute_nil new_branch.tip
    assert_equal "36060c58702ed4c2a40832c51758d5344201d89a", new_branch.tip.oid
  end

  test "can create a new branch from a commit object" do
    new_branch = @repo.create_branch("test_branch", Rugged::Commit.lookup(@repo, "5b5b025afb0b4c913b4c338a42934a3863bf3644"))

    refute_nil new_branch
    assert_equal "test_branch", new_branch.name
    assert_equal "refs/heads/test_branch", new_branch.canonical_name

    refute_nil new_branch.tip
    assert_equal "5b5b025afb0b4c913b4c338a42934a3863bf3644", new_branch.tip.oid
  end

  test "can not create a new branch from a tree" do
    assert_raises Rugged::InvalidError do
      @repo.create_branch("test_branch", Rugged::Tree.lookup(@repo, "f60079018b664e4e79329a7ef9559c8d9e0378d1"))
    end
   end

  test "can not create a new branch from a blob" do
    assert_raises Rugged::InvalidError do
      @repo.create_branch("test_branch", Rugged::Blob.lookup(@repo, "1385f264afb75a56a5bec74243be9b367ba4ca08"))
    end
  end

  test "can not create a new branch from an unknown branch" do
    assert_raises Rugged::InvalidError do
      @repo.create_branch("test_branch", "i_do_not_exist")
    end
  end

  test "can not create a new branch from an unknown commit" do
    assert_raises Rugged::OdbError do
      @repo.create_branch("test_branch", "dd15de908706711b51b7acb24faab726d2b3cb16")
    end
  end

  test "can not create a new branch from a non canonical branch name" do
    assert_raises Rugged::InvalidError do
      @repo.create_branch("test_branch", "packed")
    end
  end
end
