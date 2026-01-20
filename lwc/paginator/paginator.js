/**
 * Created by alexis on 08/03/2025.
 */

class Paginator {
    constructor(data, itemsPerPage = 10) {
        this.data = data;
        this.itemsPerPage = itemsPerPage;
        this.currentPage = 1;
        this.totalPages = Math.ceil(data.length / itemsPerPage);
    }

    getPage(page) {
        if (page < 1 || page > this.totalPages) {
            return [];
        }

        this.currentPage = page;
        const start = (page - 1) * this.itemsPerPage;
        const end = start + this.itemsPerPage;
        return this.data.slice(start, end);
    }

    hasNextPage() {
        return this.currentPage < this.totalPages;
    }

    nextPage() {
        return this.getPage(this.currentPage + 1);
    }

    hasPrevPage() {
        return this.currentPage > 1;
    }

    prevPage() {
        return this.getPage(this.currentPage - 1);
    }

    currentPage() {
        return this.currentPage;
    }

    getTotalPages() {
        return this.totalPages;
    }
}

export {Paginator}