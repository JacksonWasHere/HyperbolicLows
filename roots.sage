# ========= ROOT CLASS ====== #
# 
# == Methods ==
# * word_to_str(word) : returns string
#   - word: word object from W
#
# * in_set(others)
class Root:
    def __init__(self,*args):
        self.reflection = args[0]
        self.vector = args[1]
        self.W = args[2]

    def word_to_str(self,word):
        letters = ['a','b','c','d']
        out_str = ""
        if word == self.W.one():
            return "1"
        for s in word.reduced_word():
            out_str += letters[s]
        return out_str

    def in_set(self,others):
        for rt in others:
            if self.reflection == rt.reflection:
                return True
        return False

    def equals(self,other):
        return self.reflection == other.reflection

    def __repr__(self):
        return  self.key()

    def depth(self):
        return (self.reflection.length() + 1)/2

    def act(self,other):
        n_reflection = other * self.reflection * other
        n_vector = other*self.vector
        return Root(n_reflection,n_vector,self.W)

    def act_rt(self,other):
        self.reflection = other.reflection * self.reflection * other.reflection.inverse()
        self.vector = other.reflection * self.vector

    # Returns true when self > other
    def greater(self,other):
        if self.depth() <= other.depth():
            return False
        else:
            M = matrix([self.vector,other.vector])
            sol = None
            # Find a root in Rself + Rother that is smaller than self
            for beta in Smalls:
                if beta.depth() < self.depth():
                    try:
                        sol = M.solve(beta.vector)
                        if sol[0] > 0 and sol[1] > 0:
                            return True
                    except ValueError:
                        sol = None
        return False

    def froot(self):
        """TODO: Docstring for froot.

        :f: TODO
        :returns: TODO

        """
        vFloat = self.vector
        return f"{float(vFloat[0]):f}, {float(vFloat[1]):f}, {float(vFloat[2]):f}"

    def key(self):
        conj = self.reflection.absolute_chain_reflections()[0].reduced_word()
        #print(conj)
        ndx = (len(conj) - 1)/2
        return self.word_to_str(self.W.from_reduced_word(conj[:ndx]))+":"+str(conj[ndx])

    def vect(self):
        """Returns the string form of the vector

        :returns: string

        """
        return str

# The following are used to calculate various things


class R3System:

    """Docstring for R3System. """

    def __init__(self,m12,m13,m23):
        """TODO: to be defined. """
        self.W = CoxeterGroup([[1,m12,m13],[m12,1,m23],[m13,m23,1]],index_set=[0,1,2])
        self.S = self.W.gens()
        self.N = self.W.index_set()
        self.Kb = self.W.bilinear_form()
        self.positive_roots = []

        self.V = VectorSpace(Frac(self.W.base_ring()),len(self.S))
        self.alpha = self.V.basis()

    def root_from_key(self,key):
        letters = ['a','b','c','d']
        b_root = int(key[-1:])
        word = key[:-2]
        reflection = self.str_to_word(word + letters[b_root] + word[::-1])
        vector = self.str_to_word(word) * self.alpha[b_root]
        return Root(reflection,vector,self.W)

    def short_inv(self,word):
        parts = word.reduced_word()
        w_c = self.W.one()
        invs = []
        for s_i in parts:
            # Get the root
            a_i = self.alpha[s_i]
            vect = w_c * a_i

            # Get the reflection
            w_c = w_c * self.S[s_i]
            refl = w_c * self.S[s_i] * (w_c.inverse())

            if (refl*word).length() == word.length() - 1:
                invs.append(Root(refl,vect,self.W))
        return invs


    def inv_set(self,word):
        parts = word.reduced_word()
        w_c = self.W.one()
        invs = []
        for s_i in parts:
            # Get the root
            a_i = self.alpha[s_i]
            vect = w_c * a_i

            # Get the reflection
            w_c = w_c * self.S[s_i]
            refl = w_c * self.S[s_i] * (w_c.inverse())

            invs.append(Root(refl,vect,self.W))
        return invs


    # This result will convert a list of roots into a list of the corresponding keys
    def keyed(self,roots):
        out = []
        for root in roots:
            out.append(root.key())
        return out

    def word_to_str(self,word):
        letters = ['a','b','c','d']
        out_str = ""
        if word == self.W.one():
            return "1"
        for s in word.reduced_word():
            out_str += letters[s]
        return out_str

    def str_to_word(self,wstr):
        letters = {'a':0,'b':1,'c':2,'d':3}
        red_word = []
        if wstr == '1':
            return self.W.one()
        for l in wstr:
            if not (l == '1'):
                red_word.append(letters[l])
        return self.W.from_reduced_word(red_word)

    def red_word(self,word):
        return word.reduced_word()



# ========== Small Roots ========== #
#   The following function is used to check if all elements of roots are small
    def all_small(roots):
        found = 0
        for small in self.Smalls:
            for rt in roots:
                if small.vector == rt.vector:
                    found += 1
        return found == len(roots)

#   This function takes in a set of roots of a given depth and performs small reflections 
    def next_small_roots(self,previous):
        new_smalls = []
        count = 0
        # For each previous root
        for root in previous:
            # Apply generators
            for s,a_s in zip(self.S,self.alpha):
                B = root.vector * self.Kb * a_s
                # only if they are short edges
                if -1<B and B<0:
                    new_smalls.append(root.act(s))
        return new_smalls

    # Set fOut to 'v' for the verbose output that is typically given.
    # Set fOut to 'g' to get out that is ready for GLSL.
    def gen_smalls(self,fOut=''):
        print(" === Generating Small Roots === ")
        self.Alphr = [self.root_from_key('1:0'),self.root_from_key('1:1'),self.root_from_key('1:2')]
        self.Small_list = Set(self.keyed(self.Alphr))
        count = 3

        old_size = 0
        last_smalls = self.Alphr

        # Sets inherently deal with uniqueness and a new level of smalls will never be identical to the previous ones since the depth increases.

        while count > old_size:
            old_size = count

            # Go through last_smalls and append unique new roots
            last_smalls = self.next_small_roots(last_smalls)
            if fOut=='v':
                print("=====")
                for las in last_smalls:
                    print(las.key(),las.depth())

            count += len(last_smalls)
            S_last = Set(self.keyed(last_smalls))
            self.Small_list = self.Small_list.union(S_last)


        self.Smalls = []
        if fOut=='v':
            print("All smalls have been generated")
        print("Number of Smalls: ",len(self.Small_list))

        for small in self.Small_list:
            rsmall = self.root_from_key(small)
            self.Smalls.append(rsmall)

            if fOut=='v':
                print(self.word_to_str(rsmall.reflection))
                print(rsmall.vector)
                print("–"*20)
            elif fOut=='g':
                print(rsmall.froot(),end=',')

    # ========== Generates the low elements sequentially ========== #
    def next_low_elts(self,previous):
        new_lows = []
        # For each previous low
        for w in previous:
            # Check it's descent set
            Dl = w.descents(side="left")
            for s in self.N:
                # Pick a valid generator
                if not (s in Dl):
                    low_word = self.S[s] * w
                    # Now check that the inversion set is short
                    Phi_1 = Set(self.keyed(self.short_inv(low_word)))
                    if Phi_1.issubset(self.Small_list):
                        new_lows.append(low_word)

        return new_lows

    # Turns a list of words into strings
    def worded(self,words):
        out = []
        for w in words:
            out.append(self.word_to_str(w))
        return out

    # === Low Elements === #
    # The following is used to generate the low elements for the coxeter system self.
    # It takes no inputs but you MUST run gen_smalls() first since this requires the list of smalls
    # ** Data **
    # self.Lows --- Stores the list of low element keys
    def gen_lows(self,fOut=''):
        print(" === Generating Low Elements === ")
        self.Lows = Set([self.word_to_str(self.W.one())])
        previous = [self.W.one()]
        count = 1
        old_size = 0

        while count > old_size:
            old_size = count

            previous = self.next_low_elts(previous)
            count += len(previous)
            Sprev = Set(self.worded(previous))
            self.Lows = self.Lows.union(Sprev)

        print("Number of Lows:  "+str(len(self.Lows)))
        if(fOut == 'v'):
            for l in (self.Lows):
                low = self.str_to_word(l)
                for lrow in matrix(low).rows():
                    for c in lrow.list():
                        print(float(c),end=',')
                print()

        if(fOut == 'l'):
            for l in self.Lows:
                print(l)

        print("Generating low element short inversion lookup table")
        self.low_lookup()


    # This should be run soon after the low elements are generated
    # It is used to speed up the process of gate checking since the short inversions of
    # a low element are all that is checked for boundary conditions
    def low_lookup(self):
        self.Low_shorts = {}
        for low in self.Lows:
            low_sht = self.short_inv(self.str_to_word(low))
            simple_shr = Set(map(lambda a:a.key(),low_sht))
            self.Low_shorts[low] = simple_shr

        print("–"*20)

    # ======== FINAL AND GATE METHODS ======== #

    def finals(self,word):
        finals = []
        descentsR = word.descents(side = 'right')
        for root in self.short_inv(word):
            conj = word.inverse() * root.reflection * word
            if conj.length() == 1:
                if conj.reduced_word()[0] in descentsR:
                    print("equiv right action:" + self.word_to_str(conj))
                    finals.append(root)
        return finals

    # Generates the final roots for a low element in the form of strings
    # OUT: list of roots finals
    # IN:  word as a word
    def finals_l(self,word,disp=False):
        finals = []
        descentsR = word.descents(side = 'right')
        for root_k in self.Low_shorts[self.word_to_str(word)]:
            root = self.root_from_key(root_k)
            conj = word.inverse() * root.reflection * word
            if conj.length() == 1:
                if conj.reduced_word()[0] in descentsR:
                    if disp:
                        print(self.word_to_str(conj))
                    finals.append(root)
        return finals

    def is_only(root,phi_x,phi_w):
        good_found = 0
        for beta_w in phi_w:
            # print(beta_w.reflection.reduced_word())
            # If shared elt is found increase count
            if beta_w.in_set(phi_x):
                if beta_w.equals(root):
                    #print("* * Found one")
                    #print(word_to_str(w))
                    good_found += 1
                else:
                    return False
        # return true when one is found, just loop otherwise
        return good_found == 1

    def has_w_single(self,word,root):
        for low in self.Lows:
            # Look through all words in L
            #print("Check word: "+word_to_str(w))
            phi_w = self.Low_shorts[low]
            phi_x = self.Low_shorts[self.word_to_str(word)]
            # Check the number of intersections of the inversion sets
            inter = phi_w.intersection(phi_x)
            if root.key() in inter and len(inter)==1:
                return True

        # Only fails when one is never found
        return False

    def is_gate(self,word):
        finales = self.finals_l(word)

        if word.length() == 0:
            return True
        for beta in finales:
            #print(("–––"*5)+"For Beta "+ word_to_str(beta.reflection))
            if not self.has_w_single(word,beta):
                return False
        return True

    # ========== Generates the gates ========== #
    # self.Gates      ––– a list of the gates as actual word types in W
    # self.gates_list ––– a list of gates as strings
    def gen_gates(self):
        self.Gates = []
        for low in self.Lows:
            low_w = self.str_to_word(low)
            if self.is_gate(low_w):
                # Check here that it is ultra low?
                self.Gates.append(low_w)
            else:
                print(" ––– "+low+" ––– ")
        print(" === There are "+str(len(self.Gates))+" gates === ")

        self.gates_list = []

        for g in self.Gates:
            print(self.word_to_str(g))
            self.gates_list.append(self.word_to_str(g))

    # ========== AUTOMATA METHODS ========== #
    # In    –––  a word as an element of W
    # Out   –––  list of boundaries as roots
    def boundary_roots(self,word):
        boundaries = []
        for beta in self.short_inv(word):
            if self.has_w_single(word,beta):
                boundaries.append(beta)
        return boundaries

    def boundary_roots_l(self,word):
        boundaries = []
        for beta in self.Low_shorts(word):
            if self.has_w_single(word,beta):
                boundaries.append(beta)
        return boundaries


    # ==== NOT WORKING ====
    def boundary_optim(self,word):
        boundaries = []
        Phi_1 = self.short_inv(word)
        if len(Phi_1) < 3:
            return Phi_1
        for beta in Phi_1:
            found = 0
            for gamma in Phi_1:
                # Then find 2 choices of gamma such that
                # gamma is less than beta in the SHORPO
                if not (beta.equals(gamma)):
                    if gamma.less(beta):
                        pass

    # Find the boundary of ultra low elements
    def ultra_low_bound(self,word):
        return self.finals(word)

    # Check if two boundaries are equal
    def equal_boundary(self,roots_a,roots_b):
        w_str = lambda rt : self.word_to_str(rt.reflection)

        if not (len(roots_a) == len(roots_b)):
            return False

        sorted_a = sorted(roots_a,key = w_str)
        sorted_b = sorted(roots_b,key = w_str)
        for r_a,r_b in zip(sorted_a,sorted_b):
            if not r_a.equals(r_b):
                return False
        return True

    def same_lefts(self,word_a,word_b):
        DL_a = word_a.descents(side='left')
        DL_b = word_b.descents(side='left')
        if len(DL_a) == len(DL_b):
            return DL_a == DL_b
        return False

    def find_gate_b(self,word,dT_word):
        for gate in self.Gates:
            if self.same_lefts(word,gate):
                if gate.weak_le(word):
                    if gate == word:
                        return True
                    print("Same lefts",self.word_to_str(gate))
                    dT_g = self.ultra_low_bound(gate)
                    print(dT_g)
                    if self.equal_boundary(dT_g,dT_word):
                        return gate
        return None

    def find_gate(self,word):
        dT_word = self.boundary_roots(word)
        #print(dT_word)
        for gate in self.Gates:
            if self.same_lefts(word,gate):
                if gate.weak_le(word):
                    if gate == word:
                        return gate
                    #print("Same lefts",word_to_str(gate))
                    dT_g = self.ultra_low_bound(gate)
                    #print(dT_g)
                    if self.equal_boundary(dT_g,dT_word):
                        return gate
        return None

    def alph_rt(self,s):
        return Root(s,self.alpha[s.reduced_word()[0]],self.W)

    def next_states(self,state,boundary,s):
        if (state.inverse() * s).length() == state.length() + 1:
            #print(boundary[0].act(s).vector)
            test_boundary = list(map(lambda x:x.act(s),boundary))
            new_boundary = []
            new_boundary.append(self.alph_rt(s))
            for beta in new_boundary:
                if self.has_w_single(state,beta):
                    new_boundary.append(beta)

            #print(new_boundary)
            n_gate = self.find_gate(s*state)
            return (n_gate,new_boundary)
        return None
